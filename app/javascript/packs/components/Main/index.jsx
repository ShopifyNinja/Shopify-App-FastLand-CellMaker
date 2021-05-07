// main component

import React, { Component } from 'react'
import { 
  Page,
  Tabs
} from '@shopify/polaris'

import Upload from '../Upload'
import Themes from '../Themes'
import Sync from '../Sync'
import Settings from '../Settings'
import VH from '../VH'
import Destinations from '../Destinations'

class Main extends Component {

  constructor(props) {
    super(props)
    
    this.state = {
      selected: 0,
      tabs: [
        {
          id: 'upload',
          content: 'Upload',
          panelID: 'upload'
        },
        {
          id: 'sync',
          content: 'Sync',
          panelID: 'sync',
        },
        {
          id: 'themes',
          content: 'Themes',
          panelID: 'themes'
        },
        // {
        //   id: 'settings',
        //   content: 'Settings',
        //   panelID: 'settings'
        // },
        {
          id: 'vh',
          content: 'Virtual Handles',
          panelID: 'vh'
        },
        {
          id: 'destinations',
          content: 'Destinations',
          panelID: 'destinations'
        },
      ]
    }

    this.handleTabChange = this.handleTabChange.bind(this)
  }

  componentDidMount() {
  }

  // Handle tab change
  handleTabChange(selected) {
    this.setState({selected})
  }

  render() {
    const {
      selected,
      tabs
    } = this.state
    // Render tab
    const renderTab = (selected) => {
      switch(selected) {
        case 0:
          return <Upload />
          break
        case 1:
          return <Sync />
          break
        case 2:
          return <Themes />
          break
        // case 3:
        //   return <Settings />
        //   break
        case 3:
          return <VH />
        case 4:
          return <Destinations />
        default:
          null
      }
    }
    return (
      <div className="main">
        <Page fullWidth={true}>
          <Tabs tabs={tabs} selected={selected} onSelect={this.handleTabChange}>
            {renderTab(selected)}
          </Tabs>
        </Page>
      </div>
    )
  }
}

export default Main