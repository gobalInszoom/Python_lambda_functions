"""
	Class: RolesClass
	Purpose: All functions related to roles are carried here
	Created Date: 14-06-2017
"""
from __future__ import print_function
import threading
import json

class RolesClass(object):
    """docstring for ClassName"""
    def __init__(self, client, account_id):
        """Initialiser function for RolesClass"""
        self.client = client
        self.roles_to_create = []
        self.roles_created = []
        self.trust_relationship = self.get_trust_relationship(account_id)
        self.response = {}
        self.response['isError'] = False
        self.rollback = False

    def check_if_role_exist(self, roles_list):
        """check if role exist"""
        self.spawn_threads(roles_list, self.get_role)

    def get_role(self, role_name):
        """get_role"""
        try:
            self.client.get_role(RoleName=role_name)
        except self.client.exceptions.NoSuchEntityException as err:
            print ("ERROR: "+role_name+" is not present")
            self.roles_to_create.append(role_name)
        except self.client.exceptions.ClientError as err:
            self.response['isError'] = True
            self.response['type'] = err.__class__.__name__
            self.response['message'] = err.message

    def create_roles(self):
        """create_roles"""
        self.spawn_threads(self.roles_to_create, self.create_role)

    def create_role(self, role):
        """create_role"""
        try:
            self.client.create_role(RoleName=role,
                                    AssumeRolePolicyDocument=self.
                                    trust_relationship)
            self.roles_created.append(role)
        except self.client.exceptions.ClientError as err:
            self.rollback = True
            self.response['isError'] = True
            self.response['type'] = err.__class__.__name__
            self.response['message'] = err.message

    def get_trust_relationship(self, account_id):
        """get_trust_relationship"""
        trust_relationship = {}
        adfs_arn = "arn:aws:iam::"+account_id+":saml-provider/TescoADFS"
        with open('./policies/trust_relationship.json', 'r') as data_file:
            trust_relationship = json.load(data_file)
        trust_relationship['Statement'][0]['Principal']['Federated'] = adfs_arn
        return json.dumps(trust_relationship)

    def spawn_threads(self, userlist, function_name):
        """spawn_threads"""
        threads = []
        for element in userlist:
            threads.append(threading.Thread(target=function_name, args=(element,)))
            threads[-1].start()
        for thread in threads:
            thread.join()

    def attach_policies(self, roles_list, account_id):
        """spawn_threads"""
        print ("iam_coming here")
        for role in self.roles_created:
            self.policy_attach(roles_list[role], role, account_id)

    def policy_attach(self, policy_list, role, account_id):
        """spawn_threads"""
        for policy in policy_list:
            arn = 'arn:aws:iam::'+account_id+":policy/"+policy
            self.client.attach_role_policy(RoleName=role, PolicyArn=arn)

    def delete_roles(self, input_roles_policies, account_id):
        """delete the roles if the rollback is put ons"""
        arn_policies = []
        delete_role_flag = True
        for role in self.roles_created:
            policies = input_roles_policies[role]
            arn_policies = list(map((lambda policy: "arn:aws:iam::"+
                                     str(account_id)+":policy/"+
                                     policy), policies))
            #Detach policy; if detach policy is True then delete the role
            if self.detach_policy(role, arn_policies):
                try:
                    self.client.delete_role(RoleName=role)
                except self.client.exceptions.NoSuchEntityException:
                    delete_role_flag = False
                except self.client.exceptions.ClientError:
                    delete_role_flag = False
            else:
                delete_role_flag = False
        print("Delete role response"+ str(delete_role_flag))
        return delete_role_flag

    def detach_policy(self, role, arn_policies):
        """Detach all the policies from the role"""
        try:
            for arn in arn_policies:
                self.client.detach_role_policy(RoleName=role, PolicyArn=arn)
        except self.client.exceptions.NoSuchEntityException:
            return False

        return True
