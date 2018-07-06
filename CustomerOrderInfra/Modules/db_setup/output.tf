output "couchbase_sg_out" {
    value = "${module.couchbase_sg.couchbase_sg_out}"
}
output "couchbase_url" {
    value = "${module.couchbase_elb.http_elb_ip}"
}
