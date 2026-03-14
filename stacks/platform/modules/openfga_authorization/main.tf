resource "openfga_store" "this" {
  name = var.store_name
}

data "openfga_authorization_model_document" "this" {
  dsl = file("${path.module}/model.fga")
}

resource "openfga_authorization_model" "this" {
  store_id   = openfga_store.this.id
  model_json = data.openfga_authorization_model_document.this.result
}
