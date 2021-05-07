// Display component

import React, { Component } from 'react'
import {
  Loading,
  Layout,
  Card,
  OptionList,
  Checkbox
} from '@shopify/polaris'
import {
  loadThemes,
  updateThemes,
  isUpdatingThemes
} from '../../api'
import {
  arrayEquals
} from '../../utils'

class Display extends Component {
  constructor(props) {
    super(props)
    
    this.state = {
      flag: {
        isLoading: false,
        isInstalling: false,
        selectAll: false,
      },
      data: {
        themes: [],
        selectedThemes: [],
        oldSelectedThemes: []
      }
    }

    this.handleUpdateThemes = this.handleUpdateThemes.bind(this)
    this.checkInstallationStatus = this.checkInstallationStatus.bind(this)
    this.handleSelectThemes = this.handleSelectThemes.bind(this)
    this.handleSelectAll = this.handleSelectAll.bind(this)
  }

  componentDidMount() {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isLoading: true
      }
    }), () => {
      loadThemes().then(res => {
        console.log('>>> Themes')
        this.setState(prevState => ({
          data: {
            ...prevState.data,
            themes: res.data.themes,
            selectedThemes: res.data.installed_theme_ids,
            oldSelectedThemes: res.data.installed_theme_ids
          },
          flag: {
            ...prevState.flag,
            selectAll: res.data.themes.length == res.data.installed_theme_ids.length
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

  handleUpdateThemes = () => {
    console.log('>>> Starting installation')
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        isInstalling: true
      }
    }))

    const { data } = this.state
    updateThemes({
      selected_themes: data.selectedThemes
    }).then(res => {
      this.intervalInstall = setInterval(this.checkInstallationStatus, 5000)
    }).catch(err => {
      console.log(`!!! ERROR: ${err}`)
    })
  }

  checkInstallationStatus = async () => {
    try {
      const { data } = await isUpdatingThemes()

      if(data.completed) {
        console.log('>>> Installation end')
        clearInterval(this.intervalInstall)
        this.setState(prevState => ({
          flag: {
            ...prevState.flag,
            isInstalling: false
          },
          data: {
            ...prevState.data,
            themes: data.themes,
            selectedThemes: data.installed_theme_ids,
            oldSelectedThemes: data.installed_theme_ids
          }
        }))
      }
    } catch (e) {
      console.log(e)
    }
  }

  handleSelectThemes = (selectedThemes) => {
    const { flag, data } = this.state

    if(!flag.isInstalling) {
      const allThemes = data.themes.map(theme => theme.value)
      this.setState(prevState => ({
        data: {
          ...prevState.data,
          selectedThemes: selectedThemes
        },
        flag: {
          ...prevState.flag,
          selectAll: arrayEquals(selectedThemes, allThemes)
        }
      }))
    }
  }

  handleSelectAll = (newChecked) => {
    this.setState(prevState => ({
      flag: {
        ...prevState.flag,
        selectAll: newChecked
      }
    }))

    if(newChecked) {
      const { data } = this.state

      this.setState(prevState => ({
        data: {
          ...prevState.data,
          selectedThemes: data.themes.map(theme => theme.value)
        }
      }))
    } else {
      this.setState(prevState => ({
        data: {
          ...prevState.data,
          selectedThemes: []
        }
      }))
    }
  }

  render() {
    const {
      flag,
      data
    } = this.state

    // Description
    const description = <span>
      To install the required FastLand files to your selected themes:<br />
      1. Check the appropriate boxes<br />
      2. Click "Update themes"
    </span>

    return (
      <div className="themes tab">
        {flag.isLoading ? <Loading /> : (
          <Layout>
            <Layout.AnnotatedSection
              title="Theme Installation"
              description={description}
            >
              <Card 
                title="Themes"
                primaryFooterAction={{
                  content: 'Update Themes',
                  onAction: this.handleUpdateThemes,
                  loading: flag.isInstalling,
                  disabled: arrayEquals(data.selectedThemes, data.oldSelectedThemes)
                }}
                sectioned
              >
                <Checkbox
                  label='Select All'
                  checked={flag.selectAll}
                  onChange={this.handleSelectAll}
                  disabled={flag.isInstalling}
                />
                <OptionList
                  onChange={this.handleSelectThemes}
                  options={data.themes}
                  selected={data.selectedThemes}
                  allowMultiple
                />
              </Card>
            </Layout.AnnotatedSection>
          </Layout>
        )}
      </div>
    )
  }
}

export default Display