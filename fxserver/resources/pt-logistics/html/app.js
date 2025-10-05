window.addEventListener('message', function(event) {
  if (event.data.type === 'showLogisticsPanel') {
    document.getElementById('logistics-panel').classList.remove('hidden');
    updatePanel(event.data.payload);
  }
  if (event.data.type === 'hideLogisticsPanel') {
    document.getElementById('logistics-panel').classList.add('hidden');
  }
});
function updatePanel(payload) {
  const warehouseDiv = document.getElementById('warehouse-stock');
  warehouseDiv.innerHTML = '';
  payload.warehouse.forEach(item => {
    const el = document.createElement('div');
    el.className = 'stock';
    el.textContent = `${item.label}: ${item.amount}`;
    warehouseDiv.appendChild(el);
  });
  const routesDiv = document.getElementById('routes-list');
  routesDiv.innerHTML = '';
  payload.routes.forEach(route => {
    const el = document.createElement('div');
    el.className = 'route';
    el.innerHTML = `<div class="title">${route.title}</div><div class="info">${route.info}</div>`;
    routesDiv.appendChild(el);
  });
}
function closePanel() {
  document.getElementById('logistics-panel').classList.add('hidden');
  fetch('https:
}
document.getElementById('close-btn').onclick = closePanel;
