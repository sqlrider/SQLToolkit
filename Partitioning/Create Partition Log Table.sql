CREATE TABLE [dbo].[DBA_Partition_Management_Log](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NULL,
	[LogMessage] [nvarchar](2048) NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[DBA_Partition_Management_Log] ADD  DEFAULT (getdate()) FOR [LogDate]
GO
