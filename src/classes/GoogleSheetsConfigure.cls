/**
 * Copyright (c) 2014, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/
 
/**
 * GoogleSheetsConfigure
 */
public with sharing class GoogleSheetsConfigure 
{
	//Statics
	public static final String SHEETS_TYPE_NAME = 'GoogleSheetsAPI';	
	public static final String SHEETS_TYPE_LABEL = 'Google Sheets API';

	private static String s_clientId;
	private static String s_clientSecret;
	private static String s_domain;

	public static void configure(String clientId, String clientSecret, String domain) 
	{
		configure(clientId, clientSecret, domain, false);
	}	
	
	public static void configure(String clientId, String clientSecret, String domain, Boolean purge) 
	{
		s_clientId = clientId;
		s_clientSecret = clientSecret;
		s_domain = domain;
		
		if (purge) 
		{
			purgeAll();
		}
		
		connectorTypes();
		connectors();
	}

	public static void purgeAll()
	{
		delete [SELECT id FROM Connector__c];
		delete [SELECT id FROM ConnectorType__c];
	}

	static void connectorTypes() 
	{
		List<ConnectorType__c> connectorTypes = [SELECT Name, DeveloperName__c FROM ConnectorType__c];
		List<ConnectorType__c> newConnectorTypes = new List<ConnectorType__c>();
		
		ConnectorType__c sheetsConnectorType;

		for (ConnectorType__c item : connectorTypes) 
		{
			if (item.DeveloperName__c==SHEETS_TYPE_NAME)
			{
				sheetsConnectorType = item;
			}
		}
				
		if (sheetsConnectorType==null) 
		{
			newConnectorTypes.add(new ConnectorType__c(
				Name=SHEETS_TYPE_LABEL,
				DeveloperName__c=SHEETS_TYPE_NAME,
				AuthorizationEndpoint__c='https://accounts.google.com/o/oauth2/auth',
				TokenEndpoint__c='https://accounts.google.com/o/oauth2/token',
				ClientId__c=s_clientId,
				ClientSecret__c=s_clientSecret,
				RedirectUri__c=s_domain + '/apex/connector',
				ScopeRequired__c=true,
				Scope__c='https://spreadsheets.google.com/feeds https://docs.google.com/feeds',
				ExtraUrlParameters__c='access_type=offline&approval_prompt=force',
				CallbackURL__c=''
			));
		}
				
		insert newConnectorTypes;
	}
	
	static void connectors() 
	{	
		Id sheetsConnectorTypeId;
		
		for (ConnectorType__c item : [SELECT id,DeveloperName__c FROM ConnectorType__c]) 
		{
			if (item.DeveloperName__c==SHEETS_TYPE_NAME)
			{
				sheetsConnectorTypeId = item.id;
			}
		}
		
		List<User> internalUsers = [SELECT id, Name FROM User WHERE UserType='Standard' AND IsActive=true];

		ConnectorCollection existingConnectors = new ConnectorCollection();

		for (Connector__c item : [SELECT OwnerId, ConnectorType__r.DeveloperName__c FROM Connector__c]) 
		{
			existingConnectors.add(item.OwnerId, item.ConnectorType__r.DeveloperName__c);
		}
		
		List<Connector__c> newConnectors = new List<Connector__c>();

		for (User internalUser : internalUsers) 
		{
			if (!existingConnectors.has(internalUser.Id,SHEETS_TYPE_NAME)) 
			{
				newConnectors.add(new Connector__c(
					OwnerId = internalUser.Id,
					Name = SHEETS_TYPE_LABEL + ' for ' + internalUser.Name,
					ConnectorType__c = sheetsConnectorTypeId
				));
			}
		}
		
		insert newConnectors;		
	}
	
	class ConnectorCollection 
	{
		Map<Id,Set<String>> state = new Map<Id,Set<String>>();
		
		void add(Id userId, String typeName) 
		{
			Set<String> typeNames = state.get(userId);
			if (typeNames==null) 
			{
				typeNames = new Set<String>();
				state.put(userId,typeNames);
			}
			
			typeNames.add(typeName);
		}
		
		boolean has(Id userId, String typeName) 
		{
			return (state.get(userId) == null) ? false : state.get(userId).contains(typeName);
		}
	}
}
