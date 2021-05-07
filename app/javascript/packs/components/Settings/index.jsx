// main component

import React, { Component } from 'react'
import {
  Layout,
  Card,
  Loading,
  Button,
  DataTable,
  FormLayout
} from '@shopify/polaris'

export default class Settings extends Component {

  constructor(props) {
    super(props)
    
    this.state = {
      flag: {
        isLoading: false,
        isReporting: false
      },
      data: {
        rows: [
          ['handle', 'A', "mstrtqpx1250", '2020/08/20', '1250', "Direct", 5],
        ]
      }
    }

    this.handleSort = this.handleSort.bind(this)
    this.handleReport = this.handleReport.bind(this)
  }

  componentDidMount() {
    
  }

  handleSort = (index, direction) => {
    
  }
  
  handleReport = () => {
    
  }
  

  render() {
    const {
      flag,
      data
    } = this.state

    return (
      <div className="tab settings">
        {flag.isLoading ? <Loading /> : (
          <Card
            sectioned
          >
            <FormLayout>
              <div className="btn-report">
                <Button primary onClick={this.handleReport}>Handle Report</Button>
              </div>
              <DataTable
                columnContentTypes={[
                  'text',
                  'text',
                  'text',
                  'text',
                  'text',
                  'text',
                  'numeric'
                ]}
                headings={[
                  'Handle',
                  'Destination',
                  'Cell set name',
                  'Last Update',
                  'Cell set ID',
                  'Update Method',
                  'Number of cells'
                ]}
                rows={data.rows}
                sortable={[true, true, true, true, true, true, true]}
                defaultSortDirection="descending"
                initialSortColumnIndex={0}
                onSort={this.handleSort}
                footerContent={`Showing ${data.rows.length} of ${data.rows.length} results`}
              />
            </FormLayout>
          </Card>
        )}
      </div>
    )
  }
}