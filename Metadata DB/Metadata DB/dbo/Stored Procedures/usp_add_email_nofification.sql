CREATE procedure [dbo].[usp_add_email_nofification]
@dependactivityname varchar(255),@Condition varchar(15)
as
declare @return table (returnvalue varchar(8000))
insert into @return select ' {
                "name": "Execute Send Mail",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "'+@dependactivityname+'",
                        "dependencyConditions": [
                            "'+@Condition+'"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "SendEmail",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true,
                    "parameters": {'
insert into @return select '"'+ConfigName+'":"'+configvalue+'"' from [dbo].[T_ConfigurationDetails]
insert into @return select '}
                }
            }
        ],
        "annotations": [
            "Wait Pipeline"
        ]
    }'

select * from @return