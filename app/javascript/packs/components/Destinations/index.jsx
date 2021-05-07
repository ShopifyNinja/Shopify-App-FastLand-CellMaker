import React, { Component, useCallback } from 'react'
import {
  Layout,
  Card,
  Loading,
  Button,
  ButtonGroup,
  DataTable,
  FormLayout, Form,
  TextField,
  Select,
  Stack,
  Modal,
  RadioButton, TextContainer
} from '@shopify/polaris'

import {
  loadDestinations,
  saveDestination,
  deleteDestination,
  isUpdatingDestinations
} from '../../api'

export default class Destinations extends Component {
  constructor(props) {
    super(props)

    this.state = {
      flag: {
        isLoading: false,
        isAdding: false,
        isSaving: false,
        isDeleting: false
      },
      data: {
        destinations: []
      },
      purposes: [
        {label: "General", value: 0},
        {label: "Special", value: 1}
      ],
      rowData: {
        id: 0,
        destination: '',
        purpose_type: 0,
        dynamic_html: ''
      }
    }

    this.handleAdd = this.handleAdd.bind(this)
    this.handleEdit = this.handleEdit.bind(this)
    this.handleDelete = this.handleDelete.bind(this)
    this.handleDestinationChange = this.handleDestinationChange.bind(this)
    this.handlePurposeChange = this.handlePurposeChange.bind(this)
    this.handleDynamicHTMLChange = this.handleDynamicHTMLChange.bind(this)
    this.handleCancel = this.handleCancel.bind(this)
    this.handleSave = this.handleSave.bind(this)
    this.handleModalOpen = this.handleModalOpen.bind(this)
    this.handleModalClose = this.handleModalClose.bind(this)
  }

  componentDidMount() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isLoading: true
      }
    }), () => {
      loadDestinations().then(res => {
        console.log('>>> Destinations');
        this.setState(prevState => ({
          data: {
            ...prevState.data,
            destinations: res.data.data,
          },
          flag: {
            ...prevState.flag,
            isLoading: false
          }
        }))
      }).catch(err => {
        console.log(`!!! ERROR: ${err}`)
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

  handleAdd = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isAdding: true
      },
      rowData: {
        id: 0,
        destination: "",
        purpose_type: 0,
        dynamic_html: ""
      }
    }))
  }

  handleEdit = (id) => {
    const { data } = this.state
    const row = data.destinations.filter(item => item.id == id)

    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isAdding: true
      },
      rowData: {
        ...prevState.rowData,
        ...row[0]
      }
    }))
  }

  handleDestinationChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        destination: selectedValue
      }
    }))
  }

  handlePurposeChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        purpose_type: parseInt(selectedValue)
      }
    }))
  }

  handleDynamicHTMLChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        dynamic_html: selectedValue
      }
    }))
  }

  handleCancel = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isAdding: false
      },
      rowData: {
        
      }
    }))
  }

  handleModalOpen = (id) => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isDeleting: true
      },
      rowData: {
        ...prevState.rowData,
        id: id
      }
    }))
  }

  handleModalClose = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isDeleting: false
      }
    }))
  }

  handleDelete = () => {
    console.log(">>> Deleting destination")
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isDeleting: false,
        isLoading: true
      }
    }))

    const { rowData } = this.state
    deleteDestination({
      id: rowData.id
    }).then(res => {
      this.intervalInstall = setInterval(this.checkInstallationStatus, 5000)
    }).catch(err => {
      console.log(`!!! ERROR: ${err}`)
    })
  }

  handleSave = () => {
    console.log('>>> Saving destination')
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isSaving: true
      }
    }))

    const { rowData } = this.state
    console.log(rowData)
    saveDestination({
      row_data: rowData
    }).then(res => {
      // this.setState(prevState => ({
      //   flag: {
      //     ...prevState.flag,
      //     isAdding: false,
      //     isSaving: false
      //   },
      //   data: {
      //     ...prevState.data,
      //     destinations: res.data.data
      //   }
      // }))
      console.log("Save completed")
      this.intervalInstall = setInterval(this.checkInstallationStatus, 5000)
    }).catch(err => {
      console.log(`!!! ERROR: ${err}`)
    })
  }

  checkInstallationStatus = async () => {
    try {
      const { data } = await isUpdatingDestinations()

      if(data.completed) {
        console.log('>>> Installation end')
        clearInterval(this.intervalInstall)
        this.setState(prevState => ({
          flag: {
            ...prevState.flag,
            isAdding: false,
            isSaving: false,
            isLoading: false
          },
          data: {
            ...prevState.data,
            destinations: data.destinations
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
      data,
      purposes,
      rowData
    } = this.state

    // Description
    const description = <span>
      To add or edit special purpose destination, <br />
      please insert "@--dynamic_html--@"<br /> 
      where you want to include Fastland Dynamic Content.<br />
    </span>

    if(flag.isAdding) {
      return (
        <div className="tab destinations">
          <Layout>
            <Layout.AnnotatedSection
              title="Add/Edit Destination"
              description={description}
            >
              <Card
                sectioned
              >
                <FormLayout>
                  <TextField 
                    label="Destination"
                    onChange={this.handleDestinationChange}
                    value={rowData.destination}
                  />
                  <Select
                    label="Purpose"
                    options={purposes}
                    onChange={this.handlePurposeChange}
                    value={rowData.purpose_type}
                  />
                  <TextField
                    label="Dynamic HTML"
                    onChange={this.handleDynamicHTMLChange}
                    value={rowData.dynamic_html}
                    disabled={rowData.purpose_type == 0}
                    multiline={10}
                  />
                </FormLayout>
              </Card>
              <div className="form-action">
                <ButtonGroup>
                  <Button onClick={this.handleCancel}>Cancel</Button>
                  <Button primary onClick={this.handleSave} loading={flag.isSaving}>Save</Button>
                </ButtonGroup>
              </div>
            </Layout.AnnotatedSection>
          </Layout>
        </div>
      )
    } else {
      const tableData = []
      data.destinations.map((row, i) => {
        const tableRow = []
        let dynamicHtml = JSON.stringify(row.dynamic_html)
console.log(typeof dynamicHtml)
        if(dynamicHtml.length > 100) {
          dynamicHtml = row.dynamic_html.substring(0, 100) + "..."
        } else {
          dynamicHtml = row.dynamic_html
        }
        tableRow.push(row.destination)
        tableRow.push(purposes[row.purpose_type].label)
        tableRow.push(dynamicHtml)
        tableRow.push(
          <ButtonGroup>
            <Button primary onClick={() => this.handleEdit(row.id)}>Edit</Button>
            <Button destructive onClick={() => this.handleModalOpen(row.id)}>Delete</Button>
          </ButtonGroup>
        )

        tableData.push(tableRow)
      })

      return (
        <div className="tab destination">
          {
            flag.isLoading ? <Loading /> : (
              <Card
                sectioned
              >
                <FormLayout>
                  <div className="btn-report">
                    <Button primary onClick={this.handleAdd}>Add new</Button>
                  </div>
                  <DataTable
                    columnContentTypes={[
                      'text',
                      'text',
                      'text',
                      'text'
                    ]}
                    headings={[
                      'Destination',
                      'Purpose',
                      'Dynamic HTML',
                      'Action'
                    ]}
                    rows={tableData}
                    footerContent={`Showing ${data.destinations.length} of ${data.destinations.length} results`}
                  />
                </FormLayout>
                <Modal
                  open={flag.isDeleting}
                  onClose={this.handleModalClose}
                  title="Delete Destination"
                  primaryAction={{
                    content: 'Delete',
                    onAction: this.handleDelete
                  }}
                  secondaryActions={[
                    {
                      content: 'Cancel',
                      onAction: this.handleModalClose
                    }
                  ]}
                >
                  <Modal.Section>
                    <TextContainer>
                      <p>
                        Are you sure want to delete this destination?
                      </p>
                    </TextContainer>
                  </Modal.Section>
                </Modal>
              </Card>
            )
          }
        </div>
      )
    }
  }
}