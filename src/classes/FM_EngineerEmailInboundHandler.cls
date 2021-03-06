global class FM_EngineerEmailInboundHandler implements Messaging.InboundEmailHandler 
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        String incidentName = email.Subject.Substring( 4, 10 );
        system.debug('###incidentName###' + incidentName);
        system.debug('###incidentNameLength###' + incidentName.length());
        FM_Incident__c incident = [ Select f.Sub_Status__c, f.heath_safety__c, f.Type__c, f.SystemModstamp, f.Supplier__c, f.Supplier_Out_Hours__c, f.Supplier_Comments__c, f.Supplier_Ack_SLA__c, f.Subject__c, f.Sub_Type__c, f.Status__c, f.Start_In_Hours__c, f.Session_ID__c, f.Raised_By__c, f.Priority__c, f.Phone__c, f.PO_Number__c, f.PO_Number_Required__c, f.OwnerId, f.Other__c, f.Operational_efficiency__c, f.On_Site_Arrival_Time__c, f.Name, f.Location__c, f.Location_Street__c, f.Location_County__c, f.Location_City__c, f.LastModifiedDate, f.LastModifiedById, f.LastActivityDate, f.IsDeleted, f.Id, f.FM_Out_of_Office__c, f.End_In_Hours__c, f.Email__c, f.Description__c, f.Created_By_FM_Team__c, f.CreatedDate, f.CreatedById, f.Additional_Information__c, f.Acknowledgement_Time__c, f.Acknowledgement_SLA_Status__c, f.Acknowledgement_Date_Time__c 
                                      From FM_Incident__c f
                                     Where Name =: incidentName.trim() ];
        
        String[] mailMessage = email.plainTextBody.Split(':', 2);
        
        FM_Supplier_Response__c supplierResponse = new FM_Supplier_Response__c();
        supplierResponse.Incident__c = incident.Id;
        //supplierResponse.Title__c = incident.Name + ' - ' + incident.Subject__c + ' - ' + incident.Status__c + ' - ' + 'Engineer Entry';
        supplierResponse.Message_Body__c = mailMessage[1]; // this is the mail body EXCLUDING the status field.
        supplierResponse.Incident_Status__c = mailMessage[0];
        supplierResponse.Message_Date__c = System.Now();
        supplierResponse.Received_Time__c = System.Now();
        supplierResponse.Sent_Time__c = System.Now();
        insert supplierResponse;
     
        System.debug( '====> Created supplierResponse '+ supplierResponse.Id );
        
        //incident.Sub_Status__c = supplierResponse.Incident_Status__c;
        //update incident;

        return result;
    }
    
    static testMethod void test_handleInboundEmail() 
    {
        //create business hours
        BusinessHours bH = [select id from businesshours where IsDefault=true];
        
        // create supplier
        FM_Supplier__c supplier = new FM_Supplier__c ();
        supplier.Name = 'TestSupplier';
        insert supplier;
        
        // create location
        FM_Location__c location = new FM_Location__c ();
        location.Name = 'TestLocation';
        location.Midlands_Cluster__c = true;
        insert location;
        
        // create rule
        FM_Service_Level__c rule = new FM_Service_Level__c ();
        rule.Location__c = location.Id;
        rule.Business_Hours_In__c = bH.Id;
        rule.Business_Hours_Out__c = bH.Id;
        rule.Scope__c = 'Cleaning';
        rule.Supplier__c = supplier.Id;
        rule.In_Hours_Acknowledgement_SLA__c = 2.5;
        rule.Out_Hours_Acknowledgement_SLA__c = 5;
        rule.Start_In_Hours__c = 9;
        rule.End_In_Hours__c = 17;
        rule.Priority_Level__c = 'P4';
        insert rule;
        
        // create incident for test
        FM_Incident__c incident = new FM_Incident__c ();
        incident.Location__c = location.Id;
        incident.Subject__c = 'IncidentTitle';
        incident.Description__c = 'IncidentDescription';
        incident.Status__c = 'Supplier Progress';
        incident.Sub_Status__c = 'Acknowledged';
        incident.Service__c = 'Cleaning';
        incident.Type__c = 'Cleaning';
        incident.Sub_Type__c = 'Cleaning';
        incident.Any_Risk_Applicable__c ='No';
        //incident.Syb_Type__c = '';
        incident.Raised_By__c = 'TestName';
        incident.Phone__c = '12345';
        incident.Email__c = 'test@test.com';
        incident.Any_Risk_Applicable__c = 'No';
        insert incident;
        
        FM_Job_Type__c jobType = new FM_Job_Type__c();
        jobType.Name = 'TestJobType';
        jobType.Specs_Number__c = '6.16W';
        insert jobType;
        
        FM_Asset__c asset = new FM_Asset__c();
        asset.Name = 'TestAssedCode';
        insert asset;
        
        FM_Job_Instance__c jobInstance = new FM_Job_Instance__c();
        jobInstance.Job_Type__c = jobType.Id;
        jobInstance.Deadline__c = System.Today() + 1;
        jobInstance.Status__c = 'Planned';
        jobInstance.Asset__c = asset.Id;
        insert jobInstance; 
        
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
     
        // setup the data for the email
        String incidentName = [ Select Name From FM_Incident__c Where Id =: incident.Id ].Name;
        System.Debug( '===> ' + incident );
        System.Debug( '===> ' + incidentName );
        email.subject = 'RE: ' + incidentName;
        email.fromname = 'FirstName LastName';
        email.plainTextBody = 'Completed: comments';
        env.fromAddress = 'someaddress@email.com';
        
        // error coz Incident.Name is not set in subject
        System.Debug( '===>' + email );
     
        // call the email service class and test it with the data in the testMethod
        FM_EngineerEmailInboundHandler emailProcess = new FM_EngineerEmailInboundHandler();
        
        Test.StartTest();
            emailProcess.handleInboundEmail( email, env );
        
            // query for the Supplier response the email service created
            //FM_Supplier_Response__c supplierResponse = [ Select Id, Incident_Status__c, Message_Body__c, Incident__c
            //                                               From FM_Supplier_Response__c
            //                                              Where Incident_Status__c= 'Completed' limit 1 ];
         
            //System.assertEquals( supplierResponse.Incident__c, incident.Id ); 
        Test.StopTest();
    }
}