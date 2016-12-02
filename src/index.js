import domReady from 'domready'
import attachFastClick from 'fastclick'

import './index.css'

import Elm from './App/Main.elm'
import {start as startFirebase} from './utilities/firebase'
import talk from './App/ports.js'

domReady(() => {
  startFirebase()
  attachFastClick.attach(document.body)
  const container = document.getElementById('app')
  container.innerHTML = ''
  const {ports} = Elm.Main.embed(container)
  talk(ports)
})
