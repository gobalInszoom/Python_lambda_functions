import unittest
import json
from compliance_check_compliance_role import lambda_handler

class CloudTrailValidationTest(unittest.TestCase):

    def setUp(self):
        self.account_id = "834873887160"
        self.event = {"account_id":self.account_id}
        self.context = {}
        self.respose = {
                           'status': True,
                           'message': 'role and attached policies are valid on the account',
                           'data':
                               {
                                  'attachedpolicy': True,
                                  'assumerole': True,
                                  'trustpolicy': True
                               }
                       }

    def testEqual(self):
        result = lambda_handler(self.event,self.context)
        self.assertEqual(result, self.respose)

if __name__ == '__main__':
    unittest.main()
