// main component

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
  loadVhs,
  saveVh,
  deleteVh
} from '../../api'

export default class VH extends Component {

  constructor(props) {
    super(props)
    
    this.state = {
      flag: {
        isLoading: false,
        isReporting: false,
        isAdding: false,
        isSaving: false,
        isDeleting: false
      },
      data: {
        vhs: []
      },
      optionData: {
        expOptions: [
          {label: "Tag", value: 0},
          {label: "Collection", value: 1},
          {label: "Vendor", value: 2},
          {label: "Product Type", value: 3}
        ]
      },
      rowData: {
        id: 0,
        name: '',
        exp1_type: 0,
        exp1_value: '',
        exp2_type: 0,
        exp2_value: '',
        condition: 0
      }
    }

    this.handleSort = this.handleSort.bind(this)
    this.handleAdd = this.handleAdd.bind(this)
    this.handleEdit = this.handleEdit.bind(this)
    this.handleDelete = this.handleDelete.bind(this)
    this.handleNameChange = this.handleNameChange.bind(this)
    this.handleExp1ValueChange = this.handleExp1ValueChange.bind(this)
    this.handleExp2ValueChange = this.handleExp2ValueChange.bind(this)
    this.handleExp1SelectChange = this.handleExp1SelectChange.bind(this)
    this.handleExp2SelectChange = this.handleExp2SelectChange.bind(this)
    this.handleRadioChange = this.handleRadioChange.bind(this)
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
      loadVhs().then(res => {
        console.log('>>> Vhs');
        console.log(res.data.data);
        this.setState(prevState => ({
          data: {
            ...prevState.data,
            vhs: res.data.data,
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

  handleSort = (index, direction) => {
    
  }
  
  handleAdd = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isAdding: true
      }
    }))
  }

  handleEdit = (id) => {
    const { data } = this.state
    const row = data.vhs.filter(item => item.id == id)

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

  handleNameChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        name: selectedValue
      }
    }))
  }

  handleExp1SelectChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        exp1_type: parseInt(selectedValue)
      }
    }))
  }

  handleExp1ValueChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        exp1_value: selectedValue
      }
    }))
  }

  handleExp2SelectChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        exp2_type: parseInt(selectedValue)
      }
    }))
  }

  handleExp2ValueChange = (selectedValue) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        exp2_value: selectedValue
      }
    }))
  }

  handleRadioChange = (checked, id) => {
    this.setState(prevState => ({
      rowData: {
        ...prevState.rowData,
        condition: id == 'and' ? 0 : 1
      }
    }))
  }

  handleCancel = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isAdding: false
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
    console.log(">>> Deleting virtual handle")
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isDeleting: false,
        isLoading: true
      }
    }))

    const { rowData } = this.state
    deleteVh({
      id: rowData.id
    }).then(res => {
      this.setState(prevState => ({
        flag: {
          ...prevState.flag,
          isLoading: false
        },
        data: {
          ...prevState.data,
          vhs: res.data.data
        }
      }))
    }).catch(err => {
      console.log(`!!! ERROR: ${err}`)
    })
  }

  handleSave = () => {
    console.log('>>> Saving virtual handle')
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isSaving: true
      }
    }))

    const { rowData } = this.state
    saveVh({
      row_data: rowData
    }).then(res => {
      this.setState(prevState => ({
        flag: {
          ...prevState.flag,
          isAdding: false,
          isSaving: false
        },
        data: {
          ...prevState.data,
          vhs: res.data.data
        }
      }))
    }).catch(err => {
      console.log(`!!! ERROR: ${err}`)
    })
  }
  
  render() {
    const {
      flag,
      data,
      optionData,
      rowData
    } = this.state

    if(flag.isAdding) {
      return (
        <div className="tab vh">
          <Card
            title="Name"
            sectioned
          >
            <FormLayout>
              <TextField 
                label="Value"
                onChange={this.handleNameChange}
                value={rowData.name}
              />
            </FormLayout>
          </Card>
          <Card
            title="Expression 1"
            sectioned
          >
            <FormLayout>
              <Select
                label="Type"
                options={optionData.expOptions}
                onChange={this.handleExp1SelectChange}
                value={rowData.exp1_type}
              />
              <TextField 
                label="Value"
                onChange={this.handleExp1ValueChange}
                value={rowData.exp1_value}
              />
            </FormLayout>
          </Card>
          <Card
            title="Expression 2"
            sectioned
          >
            <FormLayout>
              <Select
                label="Type"
                options={optionData.expOptions}
                onChange={this.handleExp2SelectChange}
                value={rowData.exp2_type}
              />
              <TextField 
                label="Value"
                onChange={this.handleExp2ValueChange}
                value={rowData.exp2_value}
              />
            </FormLayout>
          </Card>
          <Card
            title="Condition"
            sectioned
          >
            <Stack vertical>
              <RadioButton
                label="And"
                checked={rowData.condition === 0}
                id="and"
                name="condition"
                value={rowData.condition}
                onChange={this.handleRadioChange}
              />
              <RadioButton
                label="Or"
                id="or"
                name="condition"
                value={rowData.condition}
                checked={rowData.condition === 1}
                onChange={this.handleRadioChange}
              />
            </Stack>
          </Card>
          <div className="form-action">
            <ButtonGroup>
              <Button onClick={this.handleCancel}>Cancel</Button>
              <Button primary onClick={this.handleSave} loading={flag.isSaving}>Save</Button>
            </ButtonGroup>
          </div>
        </div>
      )
    } else {
      const tableData = []
      data.vhs.map((row, i) => {
        const tableRow = []
        tableRow.push(row.name)
        tableRow.push(optionData.expOptions[row.exp1_type].label)
        tableRow.push(row.exp1_value)
        tableRow.push(optionData.expOptions[row.exp2_type].label)
        tableRow.push(row.exp2_value)
        tableRow.push(row.condition == 0 ? 'And' : 'Or')
        tableRow.push(
          <ButtonGroup>
            <Button primary onClick={() => this.handleEdit(row.id)}>Edit</Button>
            <Button destructive onClick={() => this.handleModalOpen(row.id)}>Delete</Button>
          </ButtonGroup>
        )

        tableData.push(tableRow)
      })

      return (
        <div className="tab vh">
          {
          flag.isLoading ? <Loading /> : (
            <Card
              sectioned
            >
              <FormLayout>
                <div className="btn-report">
                  <Button primary onClick={this.handleAdd}>Add New</Button>
                </div>
                <DataTable
                  columnWidths={[
                    15,
                    15,
                    10,
                    15,
                    10,
                    10,
                    25
                  ]}
                  columnContentTypes={[
                    'text',
                    'text',
                    'text',
                    'text',
                    'text',
                    'text',
                    'text'
                  ]}
                  headings={[
                    'Name',
                    'Expression1 Type',
                    'Expression1 Value',
                    'Expression2 Type',
                    'Expression2 Value',
                    'Condition',
                    'Action'
                  ]}
                  rows={tableData}
                  footerContent={`Showing ${data.vhs.length} of ${data.vhs.length} results`}
                />
              </FormLayout>
              <Modal
                open={flag.isDeleting}
                onClose={this.handleModalClose}
                title="Delete virtual handle?"
                primaryAction={{
                  content: "Delete",
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
                      Are you sure want to delete this product?
                    </p>
                  </TextContainer>
                </Modal.Section>
              </Modal>
            </Card>
          )}
        </div>
      )
    }
  }
}