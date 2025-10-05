const app = new Vue({
  el: '#app',
  data: {
    loaded: false,
    props: [],
    me: '',
    modal: false,
    modalTitle: '',
    modalInput: false,
    modalValue: '',
    modalPlaceholder: '',
    modalAction: null,
    modalProp: null,
  },
  methods: {
    close() {
      fetch('https:
    },
    listSale(id) {
      this.openModal('Preço de venda', true, 'Preço (€)', v => this.send('listSale', { id, price: v }));
    },
    listRent(id) {
      this.openModal('Preço de arrendamento', true, 'Preço por período (€)', v => this.send('listRent', { id, price: v }));
    },
    unlist(id) { this.send('unlist', { id }); },
    buy(id) { this.send('buy', { id }); },
    rent(id) { this.send('rent', { id }); },
    renewRent(id) { this.send('renewRent', { id }); },
    withdraw(id) { this.send('withdraw', { id }); },
    transfer(id) {
      this.openModal('CitizenID do novo proprietário', true, 'CitizenID', v => this.send('transfer', { id, target: v }));
    },
    giveKeys(id) {
      this.openModal('CitizenID para dar chaves', true, 'CitizenID', v => this.send('giveKeys', { id, target: v }));
    },
    revokeKeys(id) {
      this.openModal('CitizenID para revogar chaves', true, 'CitizenID', v => this.send('revokeKeys', { id, target: v }));
    },
    evict(id) {
      this.openModal('CitizenID do inquilino a despejar', true, 'CitizenID', v => this.send('evict', { id, target: v }));
    },
    openModal(title, input, placeholder, action) {
      this.modal = true;
      this.modalTitle = title;
      this.modalInput = input;
      this.modalPlaceholder = placeholder || '';
      this.modalAction = action;
      this.modalValue = '';
    },
    modalConfirm() {
      if (this.modalAction) this.modalAction(this.modalValue);
      this.modal = false;
    },
    modalCancel() {
      this.modal = false;
    },
    send(action, data) {
      fetch(`https:
    },
  },
});
window.addEventListener('message', e => {
  const d = e.data||{};
  if(d.action==='open') {
    app.loaded = false;
    app.props = d.props||[];
    app.me = d.me||'';
    setTimeout(()=>{app.loaded=true;},200);
  }
});
window.addEventListener('keydown', (ev) => {
  if (ev.key === 'Escape' || ev.key === 'Backspace') {
    if (app.modal) {
      app.modal = false;
      ev.preventDefault();
    } else if (app.loaded) {
      app.close();
      ev.preventDefault();
    }
  }
});
