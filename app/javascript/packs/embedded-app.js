// embedded-app.js

import React from 'react'
import ReactDOM from 'react-dom'
import { AppProvider } from '@shopify/polaris'
import en from '@shopify/polaris/locales/en.json'
import App from './app'
// import '@shopify/polaris/styles.css'

if( document.readyState !== 'loading' ) {
  InitCode()
} else {
  document.addEventListener('DOMContentLoaded', function () {
    InitCode()
  })
}

function InitCode() {
  ReactDOM.render(
    <AppProvider i18n={en}>
      <App />
    </AppProvider>,
    document.body.appendChild(document.createElement('div')),
  )
}