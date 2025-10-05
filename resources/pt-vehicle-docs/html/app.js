window.addEventListener('message', (e) => {
  const data = e.data || {}
  if (data.action === 'valet:open') {
    document.getElementById('valet-plate').textContent = `Matrícula: ${data.plate || 'N/D'}`
    document.getElementById('valet').classList.remove('hidden')
  } else if (data.action === 'valet:close') {
    document.getElementById('valet').classList.add('hidden')
  }
})

function post(action, payload) {
  fetch(`https://pt-vehicle-docs/${action}`, { method: 'POST', body: JSON.stringify(payload || {}) })
}

document.getElementById('valet-accept').addEventListener('click', () => {
  post('valet:accept')
})

document.getElementById('valet-decline').addEventListener('click', () => {
  post('valet:decline')
})
