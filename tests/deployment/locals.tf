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
    hasync = {
      name             = "sn-test-hasync"
      address_prefixes = ["10.100.10.32/28"]
    }
    mgmt = {
      name             = "sn-test-mgmt"
      address_prefixes = ["10.100.10.48/28"]
    }
  }
}
