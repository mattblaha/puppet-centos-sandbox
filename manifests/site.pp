node default {
  include base
}

node /puppet/ {
  include puppetmaster
  include base
}
