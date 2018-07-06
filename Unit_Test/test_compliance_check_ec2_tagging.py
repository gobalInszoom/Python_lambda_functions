#!/usr/bin/python2.7

import unittest
from compliance_check_ec2_tagging import check_tesco_std
from compliance_check_ec2_tagging import check_possible_tagvalues
from compliance_check_ec2_tagging import lambda_handler

class ec2_tagging_TestCase(unittest.TestCase):
    """Tests for compliance_check_ec2_tagging.py"""

    def test_tags_adhere_tesco_std(self):
        """Is ec2 tag key & value adhere to  tesco standards
        also check  mandatory key exists"""
        global instance_keys
        global instanceid
        self.instanceid = ""
        self.instance_keys = {}
        self.instance_keys['Name'] = 'test'
        """ mandatory keys starts"""
        self.instance_keys['tesco_environment_class'] = 'uat'
        self.instance_keys['tesco_application'] = 'srd'
        self.instance_keys['tesco_tier'] = 'app'
        self.instance_keys['tesco_version'] = '1.0.0'
        self.instance_keys['tesco_status'] = 'inactive'
        self.instance_keys['tesco_service_id'] = 'ppd'
        self.instance_keys['tesco_importance'] = 'normal'
        self.instance_keys['tesco_review_date'] = '21/09/2014'
        """ madatory keys end"""

        self.instance_keys['tesco_name'] = 'srd_test' # ignore  not a mandatory key
        self.instance_keys['tesco_environment'] = 'prod' # ignore  not a mandatory key


        self.instanceid = 'i-00e4cc91c9ad08914'        
        self.assertTrue(check_tesco_std(self.instanceid, self.instance_keys))

    def test_tesco_possible_tag_values(self):
        """ Check each tag value adhere to tesco possible values"""
        global instance_keys
        global instanceid
        global region
        global taginfo
        self.instanceid = ""
        self.instance_keys = {}
        self.instance_keys['Name'] = 'test'
        self.instance_keys['tesco_environment_class'] = 'uat'
        self.instance_keys['tesco_application'] = 'srd'
        self.instance_keys['tesco_tier'] = 'app'
        self.instance_keys['tesco_version'] = '1.0.0'
        self.instance_keys['tesco_status'] = 'inactive'
        self.instance_keys['tesco_service_id'] = 'ppd'
        self.instance_keys['tesco_importance'] = 'normal'
        self.instance_keys['tesco_review_date'] = '21/12/2014'
        self.instance_keys['tesco_name'] = 'srd_test' # ignore as not a mandatory key
        self.instance_keys['tesco_environment'] = 'prod' # ignore as not a mandatory key
        self.assertTrue(check_possible_tagvalues(self.instanceid, 'ap-south-1', 'ec2.Instance(id=i-0c36eabf26942719f).eu-west-1', self.instance_keys))

    def test_ec2_tagging(self):
        """ Execute all test cases agianst target account"""
        self.account_id = "531973092423"
        self.event = {"account_id":self.account_id}
        self.context = {}
        self.assertTrue(lambda_handler(self.event, self.context))

            
if __name__ == '__main__':
    unittest.main()

