// app.jsx

import React, { Component } from 'react'
import { 
  BrowserRouter as Router,
  Switch, 
  Route 
} from 'react-router-dom'
import { Frame } from '@shopify/polaris'
import routes from './routes'

class App extends Component {
  render() {
    return (
      <Frame>
        <Router>
          <Switch>
            {routes.map((route) => (
              <Route
                key={route.url}
                path={route.url}
                exact={route.exact}
                component={route.component}
              />
            ))}
          </Switch>
        </Router>
      </Frame>
    )
  }
}

export default App