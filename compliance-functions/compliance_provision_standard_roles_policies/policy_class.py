from __future__ import print_function
import threading
import json
import glob

class PolicyClass(object):
    """docstring for ClassName"""
    def __init__(self, client, account_id):
        self.client = client
        self.policies_to_create = []
        self.policies_created = []
        self.account_id = account_id
        self.policy_list = self.get_policy_list()
        self.response = {}
        self.response['isError'] = False
        self.rollback = False

    def spawn_threads(self, userlist, function_name):
        ''' function spaws the threads for creation cheking '''
        threads = []
        for element in userlist:
            threads.append(threading.Thread(target=function_name, args=(element,)))
            threads[-1].start()
        for thread in threads:
            thread.join()

    def check_if_policy_exist(self):
        ''' check if the standard roles exists '''
        self.spawn_threads(self.policy_list, self.get_policy)

    def get_policy(self, policy_name):
        '''check for presence of individual policy '''
        arn = 'arn:aws:iam::'+self.account_id+":policy/"+policy_name
        try:
            self.client.get_policy(PolicyArn=arn)
        except self.client.exceptions.NoSuchEntityException as err:
            print ("ERROR: "+policy_name+" is not present")
            self.policies_to_create.append(policy_name)
        except self.client.exceptions.ClientError as err:
            self.response['isError'] = True
            self.response['type'] = err.__class__.__name__
            self.response['message'] = err.message

    def get_policy_list(self):
        ''' get the list of policies from the total files present in th folder'''
        policy_list = glob.glob("policies/tesco-*.json")
        policy_list = [policy.replace("policies/", "") for policy in policy_list]
        return [policy.replace(".json", "") for policy in policy_list]

    def create_policies(self):
        ''' create policies in their absence in the account '''
        self.spawn_threads(self.policies_to_create, self.create_policy)

    def create_policy(self, policy):
        ''' create individual policy '''
        print (policy+" will be created")
        try:
            self.client.create_policy(PolicyName=policy,
                                      PolicyDocument=self.get_policy_document(policy))
            self.policies_created.append(policy)
        except self.client.exceptions.ClientError as err:
            self.response['isError'] = True
            self.response['type'] = err.__class__.__name__
            self.response['message'] = err.message

    def get_policy_document(self, policy):
        ''' get the policy documnt from the file '''
        with open('./policies/'+policy+'.json', 'r') as data_file:
            policy_document = json.load(data_file)
        return json.dumps(policy_document)

    def delete_policies(self, account_id):
        """delete the policy if roolback is put on, return True/False"""
        arn_policies = []
        delete_policy_flag = True
        arn_policies = list(map((lambda policy: "arn:aws:iam::"+str(account_id)+":policy/"+policy), self.policies_created))
        try:
            for arn_policy in arn_policies:
                self.client.delete_policy(PolicyArn=arn_policy)
        except self.client.exceptions.NoSuchEntityException:
            delete_policy_flag = False
        except self.client.exceptions.ClientError:
            delete_policy_flag = False
        return delete_policy_flag
