import moment from 'moment'

export const formatDateTime = date_time => {
  return date_time ? moment.utc(String(date_time)).format('YYYY-MM-DD HH:mm:ss') : ''
}

export const arrayEquals = (a, b) => {
  let _a = a.sort()
  let _b = b.sort()
  return Array.isArray(_a) &&
    Array.isArray(_b) &&
    _a.length === _b.length &&
    _a.every((val, index) => val === _b[index]);
} 