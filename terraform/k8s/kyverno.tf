resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = "3.9.2"
  namespace        = "kyverno"
  create_namespace = true

  set = [
    { name = "backgroundController.enabled", value = "false" },
    { name = "cleanupController.enabled", value = "false" },
    { name = "reportsController.enabled", value = "false" },
  ]
}