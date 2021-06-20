locals {
  subnets = {
    public = {
      name             = "sn-test-public"
      address_prefixes = ["10.100.10.0/28"]
    }
    private = {
      name             = "sn-test-private"
      address_prefixes = ["10.100.10.16/28"]
    }
  }
}
