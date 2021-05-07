import request from '../utils/request'

// Load settings
export function loadSettings (data) {
  return request({
    url: '/settings',
    method: 'get',
    data: data
  })
}

// Save settings
export function saveSettings (data) {
  console.log(data)
  return request({
    url: '/settings',
    method: 'post',
    data: data
  })
}

// Sync now
export function sync (data) {
  return request({
    url: '/sync',
    method: 'post',
    data: data
  })
}

// Check sync
export function checkSync (data) {
  return request({
    url: '/sync/check',
    method: 'post',
    data: data
  })
}

// Clear All
export function clearAll (data) {
  return request({
    url: '/sync/clear',
    method: 'post',
    data: data
  })
}

// Parse file
export function parseFile(data) {
  return request({
    url: '/file/parse',
    method: 'post',
    data: data
  })
}

// Parse file
export function isParsingFile (data) {
  return request({
    url: '/file/parse/check',
    method: 'get',
    data: data
  })
}

// Get Cell Maker setting
export function getCellMakerSettings (data) {
  return request({
    url: '/settings/cellmaker',
    method: 'get',
    data: data
  })
}

// Update Cell Maker setting
export function updateCellMakerSettings (data) {
  return request({
    url: '/settings/cellmaker',
    method: 'post',
    data: data
  })
}

// Load themes
export function loadThemes (data) {
  return request({
    url: '/themes',
    method: 'get',
    data: data
  })
}

// Install files
export function updateThemes (data) {
  return request({
    url: '/themes/install',
    method: 'post',
    data: data
  })
}

// Check installation file
export function isUpdatingThemes (data) {
  return request({
    url: '/themes/install/check',
    method: 'get',
    data: data
  })
}

// VH by Yaroslav
export function loadVhs (data) {
  return request({
    url: '/vhs',
    method: 'get',
    data: data
  })
}

export function saveVh (data) {
  return request({
    url: '/vhs/save',
    method: 'post',
    data: data
  })
}

export function deleteVh (data) {
  return request({
    url: '/vhs/delete',
    method: 'post',
    data: data
  })
}

// Destination
export function loadDestinations (data) {
  return request({
    url: '/destinations',
    method: 'get',
    data: data
  })
}

export function saveDestination (data) {
  return request({
    url: '/destinations/save',
    method: 'post',
    data: data
  })
}

export function deleteDestination (data) {
  return request({
    url: '/destinations/delete',
    method: 'post',
    data: data
  })
}

export function isUpdatingDestinations (data) {
  return request({
    url: '/destinations/working',
    method: 'get',
    data: data
  })
}