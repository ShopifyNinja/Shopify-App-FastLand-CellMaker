// main component

import React, { Component } from 'react'
import {
  Layout,
  Card,
  FormLayout,
  Button,
  Loading,
  TextContainer,
  TextStyle,
  TextField,
  DataTable,
  Subheading,
  Select,
  Modal
} from '@shopify/polaris'
import {
  loadSettings,
  saveSettings,
  sync,
  checkSync,
  clearAll
} from '../../api'
import {
  formatDateTime
} from '../../utils'
import Status from '../Status'

class Sync extends Component {

  constructor(props) {
    super(props)
    
    this.state = {
      flag: {
        isLoading: false,
        isSaving: false,
        isSyncing: false,
        isClearing: false,
        isDeleting: false,
      },
      log: {
        times: '',
        sync: '',
        clear: ''
      },
      start_time: '',
      frequency: '0',
      timezone: 1,
      data: {
        logInstances: []
      },
      timezones: []
    }

    this.onChangeFrequency = this.onChangeFrequency.bind(this)
    this.onChangeTime = this.onChangeTime.bind(this)
    this.onChangeTimezone = this.onChangeTimezone.bind(this)
    this.saveTimes = this.saveTimes.bind(this)
    this.syncNow = this.syncNow.bind(this)
    this.checkSyncDone = this.checkSyncDone.bind(this)
    this.handleClearAll = this.handleClearAll.bind(this)
    this.handleModalOpen = this.handleModalOpen.bind(this)
    this.handleModalClose = this.handleModalClose.bind(this)
  }

  componentDidMount() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isLoading: true
      } 
    }))
    loadSettings().then(res => {
      let logs = res.data.logs.map(log => {
        return [
          '',
          log.status,
          formatDateTime(log.start_at),
          formatDateTime(log.end_at)
        ]
      })
      this.setState(prevState => ({
        start_time:  res.data.start_time,
        frequency: res.data.frequency,
        timezone: res.data.timezone,
        flag: {
          ...prevState.flag,
          isLoading: false
        },
        data: {
          ...prevState.data,
          logInstances: logs
        },
        timezones: res.data.timezones
      }))
    }).catch(err => {
      console.log('loadSetting error = ', err)
    })
  }

  // Handle to change frequency
  onChangeFrequency = (newFrequency) => {
    this.setState(prevState => ({
      log: {
        ...prevState.log,
        times: ''
      }
    }))

    this.setState({ frequency: newFrequency })
  }

  // Handle to change timezone
  onChangeTimezone = (newTimezone) => {
    this.setState(prevState => ({
      log: {
        ...prevState.log,
        times: ''
      }
    }))

    this.setState({ timezone: newTimezone })
  }

  // Handle to change time
  onChangeTime = (newTime) => {
    console.log(newTime)
    this.setState(prevState => ({
      log: {
        ...prevState.log,
        start_time: ''
      }
    }))

    this.setState({start_time: newTime})
  }

  handleModalOpen = () => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isDeleting: true
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

  // Save Times
  saveTimes() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isSaving: true
      },
      log: {
        ...prevState.log,
        times: ''
      }
    }))

    const {start_time, frequency, timezone} = this.state
    saveSettings({ start_time: start_time, frequency: frequency, timezone: timezone }).then(res => {
      this.setState(prevState => ({
        flag: {
          ...prevState.flag,
          isSaving: false
        },
        log: {
          ...prevState.log,
          times: 'Schedule has been updated successfully'
        }
      }))
    }).catch(err => {

    })
  }

  // Sync now
  syncNow() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isSyncing: true
      },
      log: {
        ...prevState.log,
        sync: '',
        clear: ''
      }
    }))

    sync().then(res => {
      this.intervalID = setInterval(this.checkSyncDone, 5000)
    }).catch(err => {
    })
  }

  // Check syncing is done
  async checkSyncDone() {
   try {
      console.log("check sync...")
      const res = await checkSync()
      const completed = res.data.completed
      if(completed) {
        clearInterval(this.intervalID)
        
        this.setState(prevState => ({
          flag: {
            ...prevState.flag,
            isSyncing: false
          },
          log: {
            ...prevState.log,
            sync: 'Products are synced successfully'
          }
        }))
      }
    } catch (e) {
      console.log(e);
    }
  }
  
  // Clear all sync data
  handleClearAll() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isClearing: true,
        isDeleting: false
      },
      log: {
        ...prevState.log,
        clear: '',
        sync: ''
      }
    }))

    clearAll().then(res => {
      this.setState(prevState => ({
        flag: {
          ...prevState.flag,
          isClearing: false
        },
        log: {
          ...prevState.log,
          clear: 'Sync data have been cleared successfully'
        }
      }))
    }).catch(err => {

    })
  }

  render() {
    const {
      flag,
      log,
      frequency,
      data,
      timezones,
      timezone
    } = this.state

    const frequencyOptions = [
      {label: "1", value: "1"},
      {label: "2", value: "2"},
      {label: "4", value: "4"},
      {label: "8", value: "8"},
      {label: "12", value: "12"},
      {label: "24", value: "24"}
    ]

    let {
      start_time
    } = this.state

    // const timeList = times.split(",").map((time, index) => {
    //   return (
    //     <FormLayout.Group key={index} >
    //       {index > 0 ? (
    //         <div></div>
    //       ) : (
            
    //       )}
    //       <TextField type="time" label="Time" step="0" value={time} onChange={(value) => this.onChangeTime(index, value)} />
    //     </FormLayout.Group>
    //   )
    // })
    return (
      <div className="sync tab">
        {flag.isLoading ? <Loading /> : (
          <Layout>
            <Layout.AnnotatedSection
              title="Schedule"
            >
              <Card
                title="Daily Sync"
                primaryFooterAction={{
                  content: 'Save', 
                  onAction: this.saveTimes,
                  loading: flag.isSaving
                }} 
                sectioned
              >
                {log.times && 
                  <TextContainer>
                    <TextStyle variation="positive">{log.times}</TextStyle>
                  </TextContainer>
                }
                <FormLayout>
                  <Select
                    label="Timezone"
                    options={timezones}
                    onChange={this.onChangeTimezone}
                    value={timezone}
                  />
                  <TextField type="time" label="Sync StartTime" step="0" value={start_time} onChange={this.onChangeTime} />
                  <Select 
                    label="Sync Frequency per Day"
                    options={frequencyOptions}
                    onChange={this.onChangeFrequency}
                    value={frequency}
                  />
                </FormLayout>
              </Card>
            </Layout.AnnotatedSection>
            <Layout.AnnotatedSection
              title="Logs"
            >
              <Card sectioned>
                <DataTable
                  columnContentTypes={[
                    'text',
                    'text',
                    'text',
                    'text',
                    'text'
                  ]}
                  headings={[
                    '',
                    <Subheading>Status</Subheading>,
                    <Subheading>START TIME</Subheading>,
                    <Subheading>END TIME</Subheading>,
                    ''
                  ]}
                  rows={data.logInstances}
                />
              </Card>
            </Layout.AnnotatedSection>
            <Layout.AnnotatedSection
              title="Sync"
            >
              <Card
                title="Sync"
                sectioned
              >
                {log.sync && 
                  <TextContainer>
                    <TextStyle variation="positive">{log.sync}</TextStyle>
                  </TextContainer>
                }
                <Button primary fullWidth onClick={this.syncNow} loading={flag.isSyncing} disabled={flag.isClearing}>Sync Now</Button>
              </Card>
            </Layout.AnnotatedSection>
            <Layout.AnnotatedSection
              title="Clear"
            >
              <Card
                title="Clear"
                sectioned
              >
                {log.clear && 
                  <TextContainer>
                    <TextStyle variation="positive">{log.clear}</TextStyle>
                  </TextContainer>
                }
                <Button primary fullWidth onClick={this.handleModalOpen} loading={flag.isClearing} disabled={flag.isSyncing}>Clear All</Button>
                <Modal
                  open={flag.isDeleting}
                  onClose={this.handleModalClose}
                  title="Clear?"
                  primaryAction={{
                    content: "Clear",
                    onAction: this.handleClearAll
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
                        Are you sure you want to clear all?
                      </p>
                    </TextContainer>
                  </Modal.Section>
                </Modal>
              </Card>
            </Layout.AnnotatedSection>
          </Layout>
        )}
      </div>
    )
  }
}

export default Sync