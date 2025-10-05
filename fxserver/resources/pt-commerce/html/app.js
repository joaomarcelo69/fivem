const root = document.getElementById('root');
const shopPanel = document.getElementById('shop');
const catalogDiv = document.getElementById('catalog');
const filterBar = document.querySelector('.filters');
const cartList = document.getElementById('cart-list');
const totalSpan = document.getElementById('total');
const checkoutBtn = document.getElementById('checkout');
const shopCloseBtn = document.getElementById('shop-close');
const cttPanel = document.getElementById('ctt');
const ordersDiv = document.getElementById('orders');
const cttCloseBtn = document.getElementById('ctt-close');
const pinModal = document.getElementById('pin-modal');
const pinInput = document.getElementById('pin-input');
const pinConfirm = document.getElementById('pin-confirm');
const pinCancel = document.getElementById('pin-cancel');
let pinOrderId = null;
let catalog = [];
let cart = {};
let activeCat = 'all';
function formatEuro(n){ return (n||0).toLocaleString('pt-PT'); }
function renderCatalog(){
  catalogDiv.innerHTML = '';
  const list = catalog.filter(it => activeCat==='all' || (it.category||'other')===activeCat);
  list.forEach(it => {
    const d = document.createElement('div');
    d.className = 'item';
    d.innerHTML = `<div class="item-title">${it.label}</div><div>${formatEuro(it.price)}€</div><small style="opacity:.7;">${(it.category||'')}</small><button data-id="${it.id}">Adicionar</button>`;
    d.querySelector('button').addEventListener('click', () => {
      cart[it.id] = (cart[it.id]||0) + 1;
      renderCart();
    });
    catalogDiv.appendChild(d);
  });
}
function renderCart(){
  cartList.innerHTML = '';
  let total = 0;
  Object.entries(cart).forEach(([id,qty]) => {
    const it = catalog.find(x => x.id===id);
    if(!it) return;
    total += it.price * qty;
    const row = document.createElement('div');
    row.className = 'cart-row';
    row.innerHTML = `<span>${it.label} x${qty}</span><div><button data-id="${id}" data-op="-">-</button> <button data-id="${id}" data-op="+">+</button></div>`;
    row.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const op = btn.getAttribute('data-op');
        if(op==='+' ){ cart[id] = (cart[id]||0) + 1; }
        if(op==='-') { cart[id] = Math.max(0, (cart[id]||0)-1); if(cart[id]===0) delete cart[id]; }
        renderCart();
      });
    });
    cartList.appendChild(row);
  });
  totalSpan.textContent = formatEuro(total);
}
function openShop(cat){
  catalog = cat || [];
  cart = {};
  renderCatalog();
  renderCart();
  shopPanel.classList.remove('hidden');
}
function closeShop(){
  shopPanel.classList.add('hidden');
  fetch(`https:
}
function openCtt(orders){
  ordersDiv.innerHTML='';
  (orders||[]).forEach(o => {
    const row = document.createElement('div');
    row.className = 'order-row';
    row.innerHTML = `<div><b>${o.id}</b> - ${o.method.toUpperCase()} - Total ${formatEuro(o.total)}€ ${o.assignedTo?'(atribuída)':''}</div>
    <div><button data-id="${o.id}" data-act="claim">Atribuir</button> <button data-id="${o.id}" data-act="deliver">Entregar</button></div>`;
    row.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const act = btn.getAttribute('data-act');
        fetch(`https:
      });
    });
    ordersDiv.appendChild(row);
  })
  cttPanel.classList.remove('hidden');
}
function closeCtt(){
  cttPanel.classList.add('hidden');
  fetch(`https:
}
function openPin(orderId){
  pinOrderId = orderId;
  pinInput.value = '';
  pinModal.classList.remove('hidden');
}
function closePin(){
  pinOrderId = null;
  pinModal.classList.add('hidden');
}
checkoutBtn.addEventListener('click', () => {
  const items = Object.entries(cart).map(([id,qty]) => ({ id, qty }));
  if(items.length===0) return;
  const method = (document.querySelector('input[name="delivery"]:checked')||{}).value||'meet';
  fetch(`https:
});
shopCloseBtn.addEventListener('click', closeShop);
cttCloseBtn.addEventListener('click', closeCtt);
window.addEventListener('message', (e) => {
  const d = e.data||{};
  if(d.action==='shop:open') openShop(d.catalog);
  if(d.action==='shop:close') closeShop();
  if(d.action==='ctt:open') openCtt(d.orders);
  if(d.action==='ctt:close') closeCtt();
  if(d.action==='ctt:pin') openPin(d.orderId);
});
window.addEventListener('DOMContentLoaded', () => {
  if(filterBar){
    filterBar.querySelectorAll('.flt').forEach(btn => {
      btn.addEventListener('click', () => {
        filterBar.querySelectorAll('.flt').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        activeCat = btn.getAttribute('data-cat')||'all';
        renderCatalog();
      })
    });
    const first = filterBar.querySelector('[data-cat="all"]');
      pinConfirm.addEventListener('click', () => {
        const v = (pinInput.value||'').trim();
        if(!pinOrderId || v.length===0) return;
        fetch(`https:
        closePin();
      });
      pinCancel.addEventListener('click', closePin);
    if(first) first.classList.add('active');
  }
});
