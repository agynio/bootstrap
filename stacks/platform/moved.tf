moved {
  from = module.openfga_authorization.openfga_store.this
  to   = openfga_store.authorization
}

moved {
  from = module.openfga_authorization.openfga_authorization_model.this
  to   = openfga_authorization_model.authorization
}

moved {
  from = module.openfga_authorization.data.openfga_authorization_model_document.this
  to   = data.openfga_authorization_model_document.authorization
}
