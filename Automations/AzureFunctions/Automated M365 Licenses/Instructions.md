# Custom Object

Creating your records in Freshservice is an essential part of making this automation work. The first step is creating the service catalog items, which you can reference the Freshservice KB's on. From here, create a custom object with the following object fields:


| Field Name  | Field Type | Data Source   | Dropdown Field | Required |
|-------------|------------|---------------|----------------|----------|
| LicenseType | Lookup     | Service Items | -              | Yes      |
| Group GUID  | Text       | -             | -              | Yes      |
| Sku GUID    | Text       | -             | -              | Yes      |

I've populated mine with the following records, but depending on what licenses you're offering as addons you may have different needs. Note these are the GCC High Sku ID's. You might need something else if you're in GCC or Commercial. Well, no might about it. Check the Graph API or PowerShell on this is MS's Documentation states they will not keep the information up-to-date. The Group ID is the GUID for the Group in Azure AD that you're using for Group-based licensing.


| Record ID | License Type             | Group ID                             | Sku ID                               |
|-----------|--------------------------|--------------------------------------|--------------------------------------|
| 1         | Teams Audio Conferencing | 00000000-0000-0000-0000-000000000000 | 4dee1f32-0808-4fd2-a2ed-fdd575e3a45f |
| 2         | Microsoft 365 E5         | 00000000-0000-0000-0000-000000000000 | 4eb45c5b-0d19-4e33-b87c-adfc25268f20 |
| 3         | Microsoft Project        | 00000000-0000-0000-0000-000000000000 | 64758d81-92b7-4855-bcac-06617becb3e8 |
| 4         | Microsoft Visio          | 00000000-0000-0000-0000-000000000000 | 80e52531-ad7f-44ea-abc3-28e389462f1b |
| 5         | PowerBI Pro              | 00000000-0000-0000-0000-000000000000 | 49dd7469-0b04-4996-a11a-73947c28a36e |

# Workflow Automation
![Workflow Overview](https://github.com/cooeycomrades/cooey-tools/blob/45e7a97c49966be04f1d8041d2443d838787af59/Automations/AzureFunctions/Automated%20M365%20Licenses/WorkflowOverview.PNG)

**Note:** *The DID component referenced above is not functioning due to a Microsoft Failure. Expect an update once the MS Teams PowerShell Module is fixed for CBA.*
The majority of this workflow will be tuned to the organization, but the following JSON should be used for the the two webhooks:
Check License Availability:
```json
{
"licensedSku": "{{R3.sku_guid}}",
"ticketNumber": "{{ticket.id_numeric}}",
"licenseName": "{{R3.license_type_value}}",
"operation": "verify"
}
```

Process License Assignment:
```json
{
"licensedSku": "{{R3.sku_guid}}",
"ticketNumber": "{{ticket.id_numeric}}",
"licenseName": "{{R3.license_type_value}}",
"operation": "assign",
"licensedUser": "{{ticket.actual_requester.email}}",
"licensedGroup": "{{R3.group_guid}}"
}
```

From here again, your implementation will differ, but in my case, a webhook was sent out to an Azure Function.
