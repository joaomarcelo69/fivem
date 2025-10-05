// Orders (Encomendas) app logic

function renderOrders(list) {
  const el = $("#orders-my-list");
  el.html("");
  if (!list || list.length === 0) {
    el.html('<div class="orders-empty">Sem encomendas.</div>');
    return;
  }
  list.sort((a,b)=> (b.createdAt||0)-(a.createdAt||0));
  list.forEach(o => {
    const when = moment.unix(o.createdAt||0).fromNow();
    const badge = `<span class="badge bg-${o.status==='delivered'?'success':(o.status==='assigned'?'warning':'secondary')}">${o.status}</span>`;
    const m = o.method==='mailbox' ? 'Caixa' : 'Em mão';
    const row = `<div class="order-row"><div><b>#${o.id}</b> • ${m} • ${o.total||0}€</div><div class="muted">${when} ${badge}</div></div>`;
    el.append(row);
  });
}

function setMailboxInfo(mb) {
  if (mb && mb.coords) {
    const {x,y} = mb.coords; // omit z in short view
    $("#orders-mailbox-info").text(`Definida em (${x.toFixed(1)}, ${y.toFixed(1)}) — pendentes: ${(mb.pending && mb.pending.length)||0}`);
  } else {
    $("#orders-mailbox-info").text('Sem caixa definida.');
  }
}

function ordersClose() {
  QB.Phone.Animations.TopSlideUp('.phone-application-container', 400, -160);
  QB.Phone.Animations.TopSlideUp('.orders-app', 400, -160);
  setTimeout(()=>{
    QB.Phone.Functions.ToggleApp('orders','none');
  }, 400);
  QB.Phone.Data.currentApplication = null;
}

$(document).on('click', '#orders-close', function(e){ e.preventDefault(); ordersClose(); });

$(document).on('click', '#orders-btn-setmail', function(e){
  e.preventDefault();
  // Pede ao servidor para usar as coords atuais como mailbox
  $.post('https://qb-phone/PtOrdersSetMailbox', JSON.stringify({}));
  setTimeout(()=>{ $.post('https://qb-phone/PtOrdersRefresh', JSON.stringify({})); }, 250);
});

$(document).on('click', '#orders-btn-pickup', function(e){
  e.preventDefault();
  $.post('https://qb-phone/PtOrdersPickup', JSON.stringify({}));
  setTimeout(()=>{ $.post('https://qb-phone/PtOrdersRefresh', JSON.stringify({})); }, 400);
});

// Inicialização: pedir dados
window.addEventListener('message', function(ev){
  const d = ev.data||{};
  if (d.action === 'orders:init') {
    renderOrders(d.orders||[]);
    setMailboxInfo(d.mailbox||null);
  }
});
