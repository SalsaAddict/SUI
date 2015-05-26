IF EXISTS (SELECT * FROM sys.foreign_keys WHERE [name] = N'FK_Incident_Claimant_PolicyholderId') ALTER TABLE [Incident] DROP CONSTRAINT [FK_Incident_Claimant_PolicyholderId]
IF OBJECT_ID(N'Claimant', N'U') IS NOT NULL DROP TABLE [Claimant]
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
		[DateIncident] DATE NOT NULL,
		[TimeIncident] TIME NULL,
		[BrokerId] INT NOT NULL,
		[DateBrokerAdvised] DATE NOT NULL,
		[BrokerContact] NVARCHAR(255) NULL,
		[BrokerPhone] NVARCHAR(255) NULL,
		[BrokerNarrative] NVARCHAR(max) NULL,
  [TPAId] INT NOT NULL,
		[DateTPANotified] DATE NOT NULL,
		[PolicyholderId] INT NULL,
		[CoverholderId] INT NULL,
		[PolicyReference] NVARCHAR(255) NULL,
		[PolicyInceptionDate] DATE NULL,
		[PolicyExpiryDate] DATE NULL,
		[CreatedDTO] DATETIMEOFFSET NOT NULL,
		[CreatedById] INT NOT NULL,
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		CONSTRAINT [PK_Incident] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [FK_Incident_Company_BrokerId] FOREIGN KEY ([BrokerId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Incident_Company_TPAId] FOREIGN KEY ([TPAId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [CK_Incident_DateBrokerAdvised] CHECK ([DateBrokerAdvised] >= [DateIncident]),
		CONSTRAINT [CK_Incident_DateTPANotified] CHECK ([DateTPANotified] >= [DateBrokerAdvised]),
		CONSTRAINT [CK_Incident_PolicyExpiryDate] CHECK ([PolicyExpiryDate] >= [PolicyInceptionDate]),
		CONSTRAINT [CK_Incident_UpdatedDTO] CHECK ([UpdatedDTO] >= [CreatedDTO])
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
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		[Status] BIT NOT NULL,
		[PreviousIndex] AS [Index] - 1 PERSISTED,
		[PreviousUpdateDTO] DATETIMEOFFSET NULL,
		[PreviousStatus] AS ~[Status] PERSISTED,
		CONSTRAINT [PK_IncidentStatus] PRIMARY KEY CLUSTERED ([IncidentId], [Index] DESC, [UpdatedDTO] DESC, [Status]),
		CONSTRAINT [FK_IncidentStatus_Incident] FOREIGN KEY ([IncidentId]) REFERENCES [Incident] ([Id]),
		CONSTRAINT [FK_IncidentStatus_IncidentStatusEnum] FOREIGN KEY ([Status]) REFERENCES [IncidentStatusEnum] ([Status]),
		CONSTRAINT [FK_IncidentStatus_IncidentStatus] FOREIGN KEY ([IncidentId], [PreviousIndex], [PreviousUpdateDTO], [PreviousStatus]) REFERENCES [IncidentStatus] ([IncidentId], [Index], [UpdatedDTO], [Status]),
		CONSTRAINT [CK_IncidentStatus_Index] CHECK ([Index] >= 0),
		CONSTRAINT [CK_IncidentStatus_PreviousIndex] CHECK ([PreviousIndex] = -1 OR [PreviousUpdateDTO] IS NOT NULL),
		CONSTRAINT [CK_IncidentStatus_PreviousUpdateDTO] CHECK ([PreviousUpdateDTO] <= [UpdatedDTO])
	)
GO

CREATE TABLE [Claimant] (
  [IncidentId] INT NOT NULL,
		[Id] INT NOT NULL IDENTITY (1, 1),
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[Name] AS [Forename] + N' ' + [Surname] PERSISTED,
		[Gender] NCHAR(1) NULL,
		[DateOfBirth] DATE NULL,
		CONSTRAINT [PK_Claimant] PRIMARY KEY CLUSTERED ([IncidentId], [Id]),
		CONSTRAINT [UQ_Claimant_Id] UNIQUE ([Id]),
		CONSTRAINT [UQ_Claimant_Name] UNIQUE ([IncidentId], [Name]),
		CONSTRAINT [FK_Claimant_Incident] FOREIGN KEY ([IncidentId]) REFERENCES [Incident] ([Id]),
		CONSTRAINT [FK_Claimant_Gender] FOREIGN KEY ([Gender]) REFERENCES [GenderEnum] ([Gender])
	)
GO

ALTER TABLE [Incident] ADD CONSTRAINT [FK_Incident_Claimant_PolicyholderId] FOREIGN KEY ([Id], [PolicyholderId]) REFERENCES [Claimant] ([IncidentId], [Id])
GO