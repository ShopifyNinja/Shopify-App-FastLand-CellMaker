import React, { Component } from 'react'
import {
  Loading,
  Layout,
  Card,
  FormLayout,
  TextField,
  DropZone,
  Stack,
  Thumbnail,
  Banner,
  List,
  Caption
} from '@shopify/polaris'
import { 
  getCellMakerSettings,
  updateCellMakerSettings,
  parseFile,
  isParsingFile
} from '../../api'

export default class Upload extends Component {
  constructor(props) {
    super(props)
  
    this.state = {
      flag: {
        isLoading: false,
        isSaving: false,
        isParsing: false,
        isParsed: false
      },
      data: {
        baseUrl: '',
        masterWizardID: '',
        files: [],
        acceptedFiles: [],
        rejectedFiles: [],
        errors: []
      }
    }
    
    this.handleChangeBaseURL = this.handleChangeBaseURL.bind(this)
    this.handleChangeMasterWizardID = this.handleChangeMasterWizardID.bind(this)
    
    this.handleSaveCellMakerSettings = this.handleSaveCellMakerSettings.bind(this)
    this.handleChangeBaseURL = this.handleChangeBaseURL.bind(this)
    this.handleChangeMasterWizardID = this.handleChangeMasterWizardID.bind(this)
    this.handleDrop = this.handleDrop.bind(this)
    this.handleParse = this.handleParse.bind(this)
    this.checkParsingStatus = this.checkParsingStatus.bind(this)
  }

  componentDidMount() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isLoading: true
      } 
    }), () => {
      getCellMakerSettings().then(res2 => {
        this.setState(prevState => ({
          data: {
            ...prevState.data,
            baseUrl: res2.data.base_url,
            masterWizardID: res2.data.master_wizard_id
          }
        }))
      }).catch(err => {
        console.log('!!!!! ERROR -', err)
      }).finally(() => {
        this.setState(prevState => ({
          flag: {
            ...prevState.flag,
            isLoading: false
          }
        }))
      })
    })
  }
  
  handleChangeBaseURL = (baseUrl) => {
    this.setState(prevState => ({
      data: {
        ...prevState.data,
        baseUrl: baseUrl
      }
    }))
  }

  handleChangeMasterWizardID = (masterWizardID) => {
    this.setState(prevState => ({
      data: {
        ...prevState.data,
        masterWizardID: masterWizardID
      }
    }))
  }

  handleSaveCellMakerSettings = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isSaving: true
      }
    }))

    const { data } = this.state
    updateCellMakerSettings({
      base_url: data.baseUrl,
      master_wizard_id: data.masterWizardID
    }).then(res => {      
    }).catch(err => {

    }).finally(() => {
      this.setState(prevState => ({
        flag: {
          ...prevState.flag,
          isSaving: false
        }
      }))
    })
  }

  // Tigger on any file drop
  handleDrop = (files, acceptedFiles, rejectedFiles) => {
    this.setState(prevState => ({
      data: {
        ...prevState.data,
        files: files,
        acceptedFiles: acceptedFiles,
        rejectedFiles: rejectedFiles,
        errors: []
      },
      flag: {
        ...prevState.flag,
        isParsed: false
      }
    }))
  }

  handleParse = () => {
    const { data } = this.state

    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isParsing: true,
        isParsed: false
      },
      data: {
        ...prevState.data,
        errors: [],
        files: [],
        acceptedFiles: [],
        rejectedFiles: []
      }
    }), () => {
      if(data.acceptedFiles && data.acceptedFiles[0]) {
        let formData = new FormData()
        formData.append('file', data.acceptedFiles[0])
        parseFile(formData).then(res => {
        }).catch(err => {

        }).finally(() => {
          this.intervalParse = setInterval(this.checkParsingStatus, 5000)
        })
      }
    })
  }

  checkParsingStatus = async () => {
    try {
      const { data } = await isParsingFile()
      console.log(data)
      if(data.completed) {
        clearInterval(this.intervalParse)
        this.setState(prevState => ({
          flag: {
            ...prevState.flag,
            isParsing: false,
            isParsed: true
          },
          data: {
            ...prevState.data,
            errors: data.errors
          }
        }))
      }
    } catch (e) {
      console.log(e)
    }
  }
  
  render() {
    const { 
      flag,
      data
    } = this.state
    const fileUpload = !data.files.length && <DropZone.FileUpload />
    const addedFiles = data.files.length > 0 && (
      <Stack vertical>
        {data.files.map((file, index) => (
          <Stack alignment="center" key={index}>
            <Thumbnail
              size="small"
              alt={file.name}
              source='https://cdn.shopify.com/s/files/1/0757/9955/files/New_Post.png?12678548500147524304'
            />
            <div>{file.name} <Caption>{file.size} bytes</Caption></div>
          </Stack>
        ))}
      </Stack>
    )
    const hasError = data.rejectedFiles.length > 0
    const errorMessage = hasError && (
      <Banner
        title="The following file couldn’t be uploaded:"
        status="critical"
      >
        <List type="bullet">
          {data.rejectedFiles.map((file, index) => (
            <List.Item key={index}>
              {`"${file.name}" is not supported. File type must be .xls`}
            </List.Item>
          ))}
        </List>
      </Banner>
    )
    // Parse result
    const parseFailed = data.errors != null && data.errors.length > 0 
    const parseResult = parseFailed ? (
      <Banner
        title="The file has the following errors:"
        status="critical"
      >
        <List type="bullet">
          {data.errors.map((error, index) => (
            <List.Item key={index}>
              {error}
            </List.Item>
          ))}
        </List>
      </Banner>
    ) : (
      <Banner
        title="File parsed successfully and has been submitted for processing"
        status="success"
      >
      </Banner>
    )
    return (
      <div className="upload tab">
        {flag.isLoading ? <Loading /> : (
          <Layout>
            <Layout.AnnotatedSection
              title="Upload"
            >
              <Card
                primaryFooterAction={{
                  content: 'Upload Cell Data File', 
                  onAction: this.handleParse,
                  loading: flag.isParsing,
                  disabled: data.acceptedFiles.length == 0
                }}
                sectioned
              >
                <FormLayout>
                  <Stack vertical>
                    {errorMessage}
                    <DropZone
                      label="Cell File"
                      accept="application/vnd.ms-excel"
                      errorOverlayText="File type must be .xls or xlsx"
                      onDrop={this.handleDrop}
                      disabled={flag.isParsing}
                    >
                      {addedFiles}
                      {fileUpload}
                    </DropZone>
                  </Stack>
                </FormLayout>
                <div className='result'>
                  {flag.isParsed && parseResult}
                </div>
              </Card>
            </Layout.AnnotatedSection>
            <Layout.AnnotatedSection
              title="Parameters"
            >
              <Card
                primaryFooterAction={{
                  content: 'Save', 
                  onAction: this.handleSaveCellMakerSettings,
                  loading: flag.isSaving
                }}
                sectioned>
                <FormLayout>
                  <TextField label="Base URL" value={data.baseUrl} onChange={this.handleChangeBaseURL} />
                  {/* <TextField label="Master Wizard ID" value={data.masterWizardID} onChange={this.handleChangeMasterWizardID} /> */}
                </FormLayout>
              </Card>
            </Layout.AnnotatedSection>
          </Layout>
        )}
      </div>
    )
  }
}
