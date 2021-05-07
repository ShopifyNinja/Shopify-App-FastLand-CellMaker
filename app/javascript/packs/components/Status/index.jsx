// status component

import React from 'react'

import Success_Image from 'images/Success.svg'
import Failure_Image from 'images/Failure.svg'
import In_Progress_Image from 'images/In_Progress.svg'

function Status(props) {
  const status = props.status

  if(status.includes('success')) {
    return <img src={Success_Image} />
  } else if(status.includes('failed')) {
    return <img src={Failure_Image} />
  }

  return <img src={In_Progress_Image} />
}

export default Status