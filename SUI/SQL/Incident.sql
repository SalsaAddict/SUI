IF OBJECT_ID(N'IncidentStatus', N'U') IS NOT NULL DROP TABLE [IncidentStatus]
IF OBJECT_ID(N'IncidentStatusEnum', N'U') IS NOT NULL DROP TABLE [IncidentStatusEnum]
IF OBJECT_ID(N'Incident', N'U') IS NOT NULL DROP TABLE [Incident]
IF OBJECT_ID(N'GenderEnum', N'U') IS NOT NULL DROP TABLE [GenderEnum]
GO

CREATE TABLE [GenderEnum] (
  [Gender] NCHAR(1) NOT NULL,
		[Description] NVARCHAR(6) NOT NULL,
		CONSTRAINT [PK_GenderEnum] PRIMARY KEY CLUSTERED ([Gender]),
		CONSTRAINT [UQ_GenderEnum_Description] UNIQUE ([Description])
	)
GO

INSERT INTO [GenderEnum] ([Gender], [Description])
VALUES
 (N'M', N'Male'),
	(N'F', N'Female')
GO

CREATE TABLE [Incident] (
  [Id] INT NOT NULL IDENTITY (1, 1),
		[BrokerId] INT NOT NULL,
		[DateAdvised] DATE NOT NULL,
  [AdministratorId] INT NOT NULL,
		[DateNotified] DATE NOT NULL,
		CONSTRAINT [PK_Incident] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [FK_Incident_Company_BrokerId] FOREIGN KEY ([BrokerId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Incident_Company_AdministratorId] FOREIGN KEY ([AdministratorId]) REFERENCES [Company] ([Id])
	)
GO

CREATE TABLE [IncidentStatusEnum] (
  [Status] BIT NOT NULL,
		[Description] NVARCHAR(6) NOT NULL,
		CONSTRAINT [PK_IncidentStatusEnum] PRIMARY KEY CLUSTERED ([Status]),
		CONSTRAINT [UQ_IncidentStatusEnum_Description] UNIQUE ([Description])
	)
GO

INSERT INTO [IncidentStatusEnum] ([Status], [Description])
VALUES
 (0, N'Closed'),
	(1, N'Open')
GO

CREATE TABLE [IncidentStatus] (
  [IncidentId] INT NOT NULL,
		[Index] INT NOT NULL,
		[UpdatedUTC] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		[Status] BIT NOT NULL,
		[PreviousIndex] AS [Index] - 1 PERSISTED,
		[PreviousUpdateUTC] DATETIMEOFFSET NULL,
		[PreviousStatus] AS ~[Status] PERSISTED,
		CONSTRAINT [PK_IncidentStatus] PRIMARY KEY CLUSTERED ([IncidentId], [Index] DESC, [UpdatedUTC] DESC, [Status]),
		CONSTRAINT [FK_IncidentStatus_Incident] FOREIGN KEY ([IncidentId]) REFERENCES [Incident] ([Id]),
		CONSTRAINT [FK_IncidentStatus_IncidentStatusEnum] FOREIGN KEY ([Status]) REFERENCES [IncidentStatusEnum] ([Status]),
		CONSTRAINT [FK_IncidentStatus_IncidentStatus] FOREIGN KEY ([IncidentId], [PreviousIndex], [PreviousUpdateUTC], [PreviousStatus]) REFERENCES [IncidentStatus] ([IncidentId], [Index], [UpdatedUTC], [Status]),
		CONSTRAINT [CK_IncidentStatus_Index] CHECK ([Index] >= 0),
		CONSTRAINT [CK_IncidentStatus_PreviousIndex] CHECK ([PreviousIndex] = -1 OR [PreviousUpdateUTC] IS NOT NULL),
		CONSTRAINT [CK_IncidentStatus_PreviousUpdateUTC] CHECK ([PreviousUpdateUTC] <= [UpdatedUTC])
	)
GO
