USE [Advent] 
GO

SET NOCOUNT ON
GO

IF OBJECT_ID(N'apiClaimSave', N'P') IS NOT NULL DROP PROCEDURE [apiClaimSave]
IF OBJECT_ID(N'apiClaimStatus', N'P') IS NOT NULL DROP PROCEDURE [apiClaimStatus]
IF OBJECT_ID(N'apiClaimBinder', N'P') IS NOT NULL DROP PROCEDURE [apiClaimBinder]
IF OBJECT_ID(N'apiClaim', N'P') IS NOT NULL DROP PROCEDURE [apiClaim]
IF OBJECT_ID(N'apiClaims', N'P') IS NOT NULL DROP PROCEDURE [apiClaims]
IF OBJECT_ID(N'ClaimWith', N'U') IS NOT NULL DROP TABLE [ClaimWith]
IF OBJECT_ID(N'ClaimWithEnum', N'U') IS NOT NULL DROP TABLE [ClaimWithEnum]
IF OBJECT_ID(N'vwClaimStatusCurrent', N'V') IS NOT NULL DROP VIEW [vwClaimStatusCurrent]
IF OBJECT_ID(N'ClaimStatus', N'U') IS NOT NULL DROP TABLE [ClaimStatus]
IF OBJECT_ID(N'Claim', N'U') IS NOT NULL DROP TABLE [Claim]
IF OBJECT_ID(N'apiClaimant', N'P') IS NOT NULL DROP PROCEDURE [apiClaimant]
IF OBJECT_ID(N'apiClaimants', N'P') IS NOT NULL DROP PROCEDURE [apiClaimants]
IF OBJECT_ID(N'apiIncidentSave', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentSave]
IF OBJECT_ID(N'apiIncidentDateTPANotifiedSLA', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentDateTPANotifiedSLA]
IF OBJECT_ID(N'apiIncidentDateBrokerAdvisedSLA', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentDateBrokerAdvisedSLA]
IF OBJECT_ID(N'apiIncidentCoverholder', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentCoverholder]
IF OBJECT_ID(N'apiIncidentTPA', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentTPA]
IF OBJECT_ID(N'apiIncidentBroker', N'P') IS NOT NULL DROP PROCEDURE [apiIncidentBroker]
IF OBJECT_ID(N'apiIncident', N'P') IS NOT NULL DROP PROCEDURE [apiIncident]
IF OBJECT_ID(N'apiIncidents', N'P') IS NOT NULL DROP PROCEDURE [apiIncidents]
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE [name] = N'FK_Incident_Claimant_PolicyholderId') ALTER TABLE [Incident] DROP CONSTRAINT [FK_Incident_Claimant_PolicyholderId]
IF OBJECT_ID(N'apiClaimantSave', N'P') IS NOT NULL DROP PROCEDURE [apiClaimantSave]
IF OBJECT_ID(N'Claimant', N'U') IS NOT NULL DROP TABLE [Claimant]
IF OBJECT_ID(N'vwIncidentStatusCurrent', N'V') IS NOT NULL DROP VIEW [vwIncidentStatusCurrent]
IF OBJECT_ID(N'IncidentStatus', N'U') IS NOT NULL DROP TABLE [IncidentStatus]
IF OBJECT_ID(N'Incident', N'U') IS NOT NULL DROP TABLE [Incident]
IF OBJECT_ID(N'apiGenders', N'P') IS NOT NULL DROP PROCEDURE [apiGenders]
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

CREATE PROCEDURE [apiGenders](@UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [Gender], [Description] FROM [GenderEnum] ORDER BY [Gender]
	RETURN
END
GO

CREATE TABLE [Incident] (
  [Id] INT NOT NULL IDENTITY (1, 1),
		[SysNum] AS RIGHT(REPLICATE(N'0', 8) + CONVERT(NVARCHAR(10), [Id]), 8),
		[BrokerId] INT NOT NULL,
		[DateBrokerAdvised] DATE NOT NULL,
		[BrokerContact] NVARCHAR(255) NULL,
		[BrokerPhone] NVARCHAR(25) NULL,
  [TPAId] INT NOT NULL,
		[DateTPANotified] DATE NOT NULL,
		[DateIncident] DATE NOT NULL,
		[TimeIncident] TIME NULL,
		[Description] NVARCHAR(max) NOT NULL,
		[CountryId] NCHAR(2) NOT NULL,
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
		CONSTRAINT [UQ_Incident_SysNum] UNIQUE ([SysNum]),
		CONSTRAINT [FK_Incident_Company_BrokerId] FOREIGN KEY ([BrokerId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Incident_Company_TPAId] FOREIGN KEY ([TPAId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Incident_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id]),
		CONSTRAINT [CK_Incident_Id] CHECK ([Id] BETWEEN 1 AND 99999999),
		CONSTRAINT [CK_Incident_DateBrokerAdvised] CHECK ([DateBrokerAdvised] >= [DateIncident]),
		CONSTRAINT [CK_Incident_DateTPANotified] CHECK ([DateTPANotified] >= [DateBrokerAdvised]),
		CONSTRAINT [CK_Incident_PolicyExpiryDate] CHECK ([PolicyExpiryDate] >= [PolicyInceptionDate]),
		CONSTRAINT [CK_Incident_UpdatedDTO] CHECK ([UpdatedDTO] >= [CreatedDTO])
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
		[Address] NVARCHAR(255) NULL,
		[Postcode] NVARCHAR(25) NULL,
		[CountryId] NCHAR(2) NOT NULL,
		[Phone] NVARCHAR(25) NULL,
		[Mobile] NVARCHAR(25) NULL,
		[Email] NVARCHAR(255) NULL,
		[CreatedDTO] DATETIMEOFFSET NOT NULL,
		[CreatedById] INT NOT NULL,
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		CONSTRAINT [PK_Claimant] PRIMARY KEY CLUSTERED ([IncidentId], [Id]),
		CONSTRAINT [UQ_Claimant_Id] UNIQUE ([Id]),
		CONSTRAINT [UQ_Claimant_Name] UNIQUE ([IncidentId], [Name]),
		CONSTRAINT [FK_Claimant_Incident] FOREIGN KEY ([IncidentId]) REFERENCES [Incident] ([Id]),
		CONSTRAINT [FK_Claimant_Gender] FOREIGN KEY ([Gender]) REFERENCES [GenderEnum] ([Gender]),
		CONSTRAINT [FK_Claimant_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id]),
		CONSTRAINT [CK_Claimant_UpdatedDTO] CHECK ([UpdatedDTO] >= [CreatedDTO])
	)
GO

ALTER TABLE [Incident] ADD CONSTRAINT [FK_Incident_Claimant_PolicyholderId] FOREIGN KEY ([Id], [PolicyholderId]) REFERENCES [Claimant] ([IncidentId], [Id])
GO

CREATE PROCEDURE [apiClaimantSave](
  @IncidentId INT = NULL,
  @ClaimantId INT = NULL,
		@Forename NVARCHAR(127) = NULL,
		@Surname NVARCHAR(127) = NULL,
		@Gender NCHAR(1) = NULL,
		@DateOfBirth DATE = NULL,
		@Address NVARCHAR(255) = NULL,
		@Postcode NVARCHAR(25) = NULL,
		@CountryId NCHAR(2) = NULL,
		@Phone NVARCHAR(25) = NULL,
		@Mobile NVARCHAR(25) = NULL,
		@Email NVARCHAR(255) = NULL,
		@UserId INT
 )
AS
BEGIN
 SET NOCOUNT ON
	IF @ClaimantId IS NULL BEGIN
	 INSERT INTO [Claimant] (
		  [IncidentId],
				[Forename],
				[Surname],
				[Gender],
				[DateOfBirth],
				[Address],
				[Postcode],
				[CountryId],
				[Phone],
				[Mobile],
				[Email],
				[CreatedDTO],
				[CreatedById],
				[UpdatedDTO],
				[UpdatedById]
		 )
		SELECT
		 [IncidentId] = @IncidentId,
			[Forename] = @Forename,
			[Surname] = @Surname,
			[Gender] = @Gender,
			[DateOfBirth] = @DateOfBirth,
			[Address] = @Address,
			[Postcode] = @Postcode,
			[CountryId] = @CountryId,
			[Phone] = @Phone,
			[Mobile] = @Mobile,
			[Email] = @Email,
			[CreatedDTO] = GETUTCDATE(),
			[CreatedById] = @UserId,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		SET @ClaimantId = SCOPE_IDENTITY()
	END ELSE BEGIN
	 UPDATE [Claimant]
		SET
		 [IncidentId] = @IncidentId,
			[Forename] = @Forename,
			[Surname] = @Surname,
			[Gender] = @Gender,
			[DateOfBirth] = @DateOfBirth,
			[Address] = @Address,
			[Postcode] = @Postcode,
			[CountryId] = @CountryId,
			[Phone] = @Phone,
			[Mobile] = @Mobile,
			[Email] = @Email,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		WHERE [Id] = @ClaimantId
	END
	SELECT [ClaimantId] = @ClaimantId
	RETURN @ClaimantId
END
GO


CREATE PROCEDURE [apiIncident](@IncidentId INT, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
		[IncidentId] = i.[Id],
		[SysNum] = i.[SysNum],
		[BrokerId] = i.[BrokerId],
		[DateBrokerAdvised] = i.[DateBrokerAdvised],
		[BrokerContact] = i.[BrokerContact],
		[BrokerPhone] = i.[BrokerPhone],
		[TPAId] = i.[TPAId],
		[DateTPANotified] = i.[DateTPANotified],
		[DateIncident] = i.[DateIncident],
		[TimeIncident] = i.[TimeIncident],
		[Description] = i.[Description],
		[CountryId] = i.[CountryId],
		( -- Policyholder Details
		  SELECT
		   [PolicyholderId] = i.[PolicyholderId],
					[Forename] = cmt.[Forename],
					[Surname] = cmt.[Surname],
					[Name] = cmt.[Name],
					[Gender] = cmt.[Gender],
					[DateOfBirth] = cmt.[DateOfBirth],
					[Address] = cmt.[Address],
					[Postcode] = cmt.[Postcode],
					[CountryId] = cmt.[CountryId],
					[Phone] = cmt.[Phone],
					[Mobile] = cmt.[Mobile],
					[Email] = cmt.[Email]
				FROM [Claimant] cmt
				WHERE cmt.[Id] = i.[PolicyholderId]
				FOR XML PATH (N'Policyholder'), TYPE
			),
		-- Policy Details
		[CoverholderId] = i.[CoverholderId],
		[PolicyReference] = i.[PolicyReference],
		[PolicyInceptionDate] = i.[PolicyInceptionDate],
		[PolicyExpiryDate] = i.[PolicyExpiryDate],
		-- Tracking
		[CreatedDTO] = i.[CreatedDTO],
		[CreatedById] = i.[CreatedById],
		[UpdatedDTO] = i.[UpdatedDTO],
		[UpdatedById] = i.[UpdatedById]
	FROM [Incident] i
	WHERE i.[Id] = @IncidentId
	FOR XML PATH (N'Incident')
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentBroker](@IncidentId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT
	 [BrokerId] = CONVERT(NVARCHAR(10), c.[Id]),
		[Broker] = c.[DisplayName]
	FROM [Company] c
	 LEFT JOIN [Incident] i ON @IncidentId = i.[Id] AND c.[Id] = i.[BrokerId]
	WHERE c.[RBR] & c.[Active] = 1
	 OR i.[Id] IS NOT NULL
	ORDER BY c.[DisplayName]
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentTPA](@IncidentId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT
	 [TPAId] = CONVERT(NVARCHAR(10), c.[Id]),
		[TPA] = c.[DisplayName]
	FROM [Company] c
	 LEFT JOIN [Incident] i ON @IncidentId = i.[Id] AND c.[Id] = i.[TPAId]
	WHERE c.[TPA] & c.[Active] = 1
	 OR i.[Id] IS NOT NULL
	ORDER BY c.[DisplayName]
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentCoverholder](@IncidentId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT
	 [CoverholderId] = CONVERT(NVARCHAR(10), c.[Id]),
		[Coverholder] = c.[DisplayName]
	FROM [Company] c
	 LEFT JOIN [Incident] i ON @IncidentId = i.[Id] AND c.[Id] = i.[CoverholderId]
	WHERE c.[COV] & c.[Active] = 1
	 OR i.[Id] IS NOT NULL
	ORDER BY c.[DisplayName]
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentDateBrokerAdvisedSLA](@DateIncident DATE, @DateBrokerAdvised DATE, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Days INT
	SET @Days = DATEDIFF(day, @DateIncident, @DateBrokerAdvised)
	SELECT [Class] = CASE
	 WHEN @Days < 0 THEN NULL
	 WHEN @Days <= 1 THEN N'text-success'
		WHEN @Days BETWEEN 2 AND 3 THEN N'text-warning'
		WHEN @Days > 3 THEN N'text-danger'
	END
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentDateTPANotifiedSLA](@DateBrokerAdvised DATE, @DateTPANotified DATE, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Days INT
	SET @Days = DATEDIFF(day, @DateBrokerAdvised, @DateTPANotified)
	SELECT [Class] = CASE
	 WHEN @Days < 0 THEN NULL
	 WHEN @Days <= 1 THEN N'text-success'
		WHEN @Days BETWEEN 2 AND 3 THEN N'text-warning'
		WHEN @Days > 3 THEN N'text-danger'
	END
	RETURN
END
GO

CREATE PROCEDURE [apiIncidentSave](
  @IncidentId INT = NULL,
		@BrokerId INT = NULL,
		@DateBrokerAdvised DATE = NULL,
		@BrokerContact NVARCHAR(255) = NULL,
		@BrokerPhone NVARCHAR(25) = NULL,
		@TPAId INT = NULL,
		@DateTPANotified DATE = NULL,
		@DateIncident DATE = NULL,
		@TimeIncident TIME = NULL,
		@Description NVARCHAR(max) = NULL,
		@CountryId NCHAR(2) = NULL,
		-- Policyholder Details
		@PolicyholderForename NVARCHAR(127) = NULL,
		@PolicyholderSurname NVARCHAR(127) = NULL,
		@PolicyholderGender NCHAR(1) = NULL,
		@PolicyholderDateOfBirth DATE = NULL,
		@PolicyholderAddress NVARCHAR(255) = NULL,
		@PolicyholderPostcode NVARCHAR(25) = NULL,
		@PolicyholderCountryId NCHAR(2) = NULL,
		@PolicyholderPhone NVARCHAR(25) = NULL,
		@PolicyholderMobile NVARCHAR(255) = NULL,
		@PolicyholderEmail NVARCHAR(255) = NULL,
		-- Policy Details
		@CoverholderId INT = NULL,
		@PolicyReference NVARCHAR(255) = NULL,
		@PolicyInceptionDate DATE = NULL,
		@PolicyExpiryDate DATE = NULL,
		-- Status
		@Status BIT = NULL,
		@UserId INT
 )
AS
BEGIN
 SET NOCOUNT ON

	IF @IncidentId IS NULL BEGIN
	 -- New Incident
		INSERT INTO [Incident] (
		  [BrokerId],
				[DateBrokerAdvised],
				[BrokerContact],
				[BrokerPhone],
				[TPAId],
				[DateTPANotified],
				[DateIncident],
				[TimeIncident],
				[Description],
				[CountryId],
				[CoverholderId],
				[PolicyReference],
				[PolicyInceptionDate],
				[PolicyExpiryDate],
				[CreatedDTO],
				[CreatedById],
				[UpdatedDTO],
				[UpdatedById]
			)
		SELECT
		 [BrokerId] = @BrokerId,
			[DateBrokerAdvised] = @DateBrokerAdvised,
			[BrokerContact] = @BrokerContact,
			[BrokerPhone] = @BrokerPhone,
			[TPAId] = @TPAId,
			[DateTPANotified] = @DateTPANotified,
			[DateIncident] = @DateIncident,
			[TimeIncident] = @TimeIncident,
			[Description] = @Description,
			[CountryId] = @CountryId,
			[CoverholderId] = @CoverholderId,
			[PolicyReference] = @PolicyReference,
			[PolicyInceptionDate] = @PolicyInceptionDate,
			[PolicyExpiryDate] = @PolicyExpiryDate,
			[CreatedDTO] = GETUTCDATE(),
			[CreatedById] = @UserId,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		SET @IncidentId = SCOPE_IDENTITY()
	END ELSE BEGIN
	 UPDATE [Incident]
		SET
			[BrokerId] = @BrokerId,
			[DateBrokerAdvised] = @DateBrokerAdvised,
			[BrokerContact] = @BrokerContact,
			[BrokerPhone] = @BrokerPhone,
			[TPAId] = @TPAId,
			[DateTPANotified] = @DateTPANotified,
			[DateIncident] = @DateIncident,
			[TimeIncident] = @TimeIncident,
			[Description] = @Description,
			[CountryId] = @CountryId,
			[CoverholderId] = @CoverholderId,
			[PolicyReference] = @PolicyReference,
			[PolicyInceptionDate] = @PolicyInceptionDate,
			[PolicyExpiryDate] = @PolicyExpiryDate,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		WHERE [Id] = @IncidentId
	END

	-- Policyholder Details
	DECLARE @ClaimantId INT
	SELECT @ClaimantId = [PolicyholderId], @PolicyholderCountryId = ISNULL(@PolicyholderCountryId, [CountryId]) FROM [Incident] WHERE [Id] = @IncidentId
	DECLARE @Policyholder TABLE ([ClaimantId] INT NULL UNIQUE CLUSTERED)
	INSERT INTO @Policyholder ([ClaimantId])
	EXEC @ClaimantId = [apiClaimantSave]
	 @IncidentId = @IncidentId,
		@ClaimantId = @ClaimantId,
		@Forename = @PolicyholderForename,
		@Surname = @PolicyholderSurname,
		@Gender = @PolicyholderGender,
		@DateOfBirth = @PolicyholderDateOfBirth,
		@Address = @PolicyholderAddress,
		@Postcode = @PolicyholderPostcode,
		@CountryId = @PolicyholderCountryId,
		@Phone = @PolicyholderPhone,
		@Mobile = @PolicyholderMobile,
		@Email = @PolicyholderEmail,
		@UserId = @UserId
	UPDATE [Incident] SET [PolicyholderId] = @ClaimantId WHERE [Id] = @IncidentId

	SELECT [IncidentId] = @IncidentId

	RETURN @IncidentId
END
GO

CREATE PROCEDURE [apiClaimants](@IncidentId INT, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [ClaimantId] = cmt.[Id],
		[Name] = cmt.[Name] + CASE WHEN i.[Id] IS NOT NULL THEN N' (Policyholder)' ELSE N'' END,
		[Gender] = gen.[Description],
		[DateOfBirth] = cmt.[DateOfBirth],
		[Country] = c.[Name]
	FROM [Claimant] cmt
	 LEFT JOIN [GenderEnum] gen ON cmt.[Gender] = gen.[Gender]
		JOIN [Country] c ON cmt.[CountryId] = c.[Id]
	 LEFT JOIN [Incident] i ON cmt.[IncidentId] = i.[Id] AND cmt.[Id] = i.[PolicyholderId]
	WHERE cmt.[IncidentId] = @IncidentId
	ORDER BY CASE WHEN i.[Id] IS NOT NULL THEN 0 ELSE 1 END, cmt.[Name]
	RETURN
END
GO

CREATE PROCEDURE [apiClaimant](@IncidentId INT, @ClaimantId INT, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [SysNum] = i.[SysNum],
		[ClaimantId] = cmt.[Id],
		[Forename] = cmt.[Forename],
		[Surname] = cmt.[Surname],
		[Name] = cmt.[Name],
		[Gender] = cmt.[Gender],
		[DateOfBirth] = cmt.[DateOfBirth],
		[Address] = cmt.[Address],
		[Postcode] = cmt.[Postcode],
		[CountryId] = cmt.[CountryId],
		[Phone] = cmt.[Phone],
		[Mobile] = cmt.[Mobile],
		[Email] = cmt.[Email]
	FROM [Claimant] cmt
	 JOIN [Incident] i ON cmt.[IncidentId] = i.[Id]
	WHERE cmt.[IncidentId] = @IncidentId
	 AND cmt.[Id] = @ClaimantId
	FOR XML PATH (N'Claimant'), TYPE
	RETURN
END
GO

CREATE TABLE [Claim] (
  [IncidentId] INT NOT NULL,
		[ClaimantId] INT NOT NULL,
		[Id] INT NOT NULL IDENTITY (1, 1),
		[Title] NVARCHAR(255) NOT NULL,
		[ClassId] NVARCHAR(5) NOT NULL,
		[BinderId] INT NULL,
		[CreatedDTO] DATETIMEOFFSET NOT NULL,
		[CreatedById] INT NOT NULL,
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		CONSTRAINT [PK_Claim] PRIMARY KEY NONCLUSTERED ([IncidentId], [ClaimantId], [Id]),
		CONSTRAINT [UQ_Claim_Id] UNIQUE ([Id]),
		CONSTRAINT [UQ_Claim_Title] UNIQUE CLUSTERED ([IncidentId], [ClaimantId], [Title]),
		CONSTRAINT [FK_Claim_Claimant] FOREIGN KEY ([IncidentId], [ClaimantId]) REFERENCES [Claimant] ([IncidentId], [Id]),
		CONSTRAINT [FK_Claim_ClassOfBusiness] FOREIGN KEY ([ClassId]) REFERENCES [ClassOfBusiness] ([Id]),
		CONSTRAINT [CK_Claim_UpdatedDTO] CHECK ([UpdatedDTO] >= [CreatedDTO])
	)
GO

CREATE TABLE [ClaimStatus] (
  [ClaimId] INT NOT NULL,
		[Index] INT NOT NULL,
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		[Status] BIT NOT NULL,
		[StatusDesc] AS CASE WHEN [Status] = 0 THEN N'Closed' WHEN [Index] = 0 THEN N'Open' ELSE N'Reopened' END PERSISTED,
		[PreviousIndex] AS [Index] - 1 PERSISTED,
		[PreviousUpdateDTO] DATETIMEOFFSET NULL,
		[PreviousStatus] AS ~[Status] PERSISTED,
		CONSTRAINT [PK_ClaimStatus] PRIMARY KEY CLUSTERED ([ClaimId], [Index] DESC, [UpdatedDTO] DESC, [Status]),
		CONSTRAINT [UQ_ClaimStatus_Index] UNIQUE ([ClaimId], [Index] DESC),
		CONSTRAINT [FK_ClaimStatus_Claim] FOREIGN KEY ([ClaimId]) REFERENCES [Claim] ([Id]),
		CONSTRAINT [FK_ClaimStatus_ClaimStatus] FOREIGN KEY ([ClaimId], [PreviousIndex], [PreviousUpdateDTO], [PreviousStatus]) REFERENCES [ClaimStatus] ([ClaimId], [Index], [UpdatedDTO], [Status]),
		CONSTRAINT [CK_ClaimStatus_Index] CHECK ([Index] >= 0),
		CONSTRAINT [CK_ClaimStatus_Status] CHECK ([Index] > 0 OR [Status] = 1),
		CONSTRAINT [CK_ClaimStatus_PreviousIndex] CHECK ([PreviousIndex] = -1 OR [PreviousUpdateDTO] IS NOT NULL),
		CONSTRAINT [CK_ClaimStatus_PreviousUpdateDTO] CHECK ([PreviousUpdateDTO] <= [UpdatedDTO])
	)
GO

CREATE VIEW [vwClaimStatusCurrent]
AS
WITH cte AS (
  SELECT
		 [ClaimId],
			[Index],
			[UpdatedDTO],
			[UpdatedById],
			[Status],
			[StatusDesc],
			[Row] = ROW_NUMBER() OVER (PARTITION BY [ClaimId] ORDER BY [Index] DESC)
		FROM [ClaimStatus]
	)
SELECT
 [ClaimId] = cte.[ClaimId],
	[Index] = cte.[Index],
	[UpdatedDTO] = cte.[UpdatedDTO],
	[UpdatedById] = cte.[UpdatedById],
	[UpdatedBy] = u.[Name],
	[Status] = cte.[Status],
	[StatusDesc] = cte.[StatusDesc]
FROM cte
 JOIN [User] u ON cte.[UpdatedById] = u.[Id]
WHERE cte.[Row] = 1
GO

CREATE TABLE [ClaimWithEnum] (
  [With] NVARCHAR(25) NOT NULL,
		CONSTRAINT [PK_ClaimWithEnum] PRIMARY KEY CLUSTERED ([With])
	)
GO

CREATE PROCEDURE [apiClaims](@IncidentId INT, @ClaimantId INT, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [ClaimId] = clm.[Id],
		[Title] = clm.[Title],
		[Class] = cob.[Description],
		[UMR] = bin.[UMR],
		[Incurred] = CONVERT(MONEY, 0),
		[Status] = csc.[StatusDesc]
	FROM [Claim] clm
	 JOIN [Claimant] cmt ON clm.[IncidentId] = cmt.[IncidentId] AND clm.[ClaimantId] = cmt.[Id]
		JOIN [Incident] i ON cmt.[IncidentId] = i.[Id]
		JOIN [ClassOfBusiness] cob ON clm.[ClassId] = cob.[Id]
		LEFT JOIN [Binder] bin ON clm.[BinderId] = bin.[Id]
		JOIN [vwClaimStatusCurrent] csc ON clm.[Id] = csc.[ClaimId]
	WHERE clm.[IncidentId] = @IncidentId
	 AND clm.[ClaimantId] = @ClaimantId
	ORDER BY [Title]
	RETURN
END
GO

CREATE PROCEDURE [apiClaim](@IncidentId INT, @ClaimantId INT, @ClaimId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [ClaimId] = clm.[Id],
	 [SysNum] = i.[SysNum],
		[Claimant] = cmt.[Name],
		[Title] = clm.[Title],
		[ClassId] = clm.[ClassId],
		[IncidentCountry] = ico.[Name],
		[Coverholder] = cov.[DisplayName],
		[PolicyholderCountry] = ISNULL(pco.[Name], ico.[Name]),
		[PolicyReference] = i.[PolicyReference],
		[PolicyInceptionDate] = i.[PolicyInceptionDate],
		[PolicyExpiryDate] = i.[PolicyExpiryDate],
		[BinderId] = clm.[BinderId],
		( -- Status
		  SELECT
					[Status] = csc.[Status],
					[UpdatedDTO] = csc.[UpdatedDTO],
					[UpdatedBy] = csc.[UpdatedBy],
					[DateFirstClosed] = MIN(CASE WHEN [Status] = 0 THEN [UpdatedDTO] END),
					[ReopenCount] = COUNT(CASE WHEN [Index] > 0 AND [Status] = 1 THEN 1 END)
				FROM [ClaimStatus]
				WHERE [ClaimId] = clm.[Id]
				GROUP BY [ClaimId]
				FOR XML PATH (N'Status'), TYPE
			)
	FROM [Incident] i
	 JOIN [Claimant] cmt ON i.[Id] = cmt.[IncidentId]
		JOIN [Company] cov ON i.[CoverholderId] = cov.[Id]
		JOIN [Country] ico ON i.[CountryId] = ico.[Id]
		LEFT JOIN [Claimant] ph
		  JOIN [Country] pco ON ph.[CountryId] = pco.[Id]
		 ON i.[Id] = ph.[IncidentId] AND i.[PolicyholderId] = ph.[Id]
		LEFT JOIN [Claim] clm ON cmt.[IncidentId] = clm.[IncidentId] AND cmt.[Id] = clm.[ClaimantId] AND @ClaimId = clm.[Id]
	 LEFT JOIN [vwClaimStatusCurrent] csc ON clm.[Id] = csc.[ClaimId]
	WHERE i.[Id] = @IncidentId
	 AND cmt.[Id] = @ClaimantId
	FOR XML PATH (N'Claim')
	RETURN
END
GO

CREATE PROCEDURE [apiClaimBinder](@IncidentId INT, @ClassId NVARCHAR(5), @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT DISTINCT
	 [BinderId] = CONVERT(NVARCHAR(10), b.[Id]),
		[Binder] = b.[UMR] + N': ' + CONVERT(NVARCHAR(10), b.[InceptionDate], 103) + N' to ' + CONVERT(NVARCHAR(10), b.[ExpiryDate], 103)
	FROM [Incident] i
	 LEFT JOIN [Claimant] ph ON i.[Id] = ph.[IncidentId] AND i.[PolicyholderId] = ph.[Id]
		JOIN [Binder] b ON i.[CoverholderId] = b.[CoverholderId]
		JOIN [vwTerritoryCountries] rty ON b.[RisksTerritoryId] = rty.[TerritoryId] AND i.[CountryId] = rty.[CountryId]
		JOIN [vwTerritoryCountries] dty ON b.[DomiciledTerritoryId] = rty.[TerritoryId] AND ISNULL(ph.[CountryId], i.[CountryId]) = dty.[CountryId]
		JOIN [vwTerritoryCountries] lty ON b.[LimitsTerritoryId] = lty.[TerritoryId] AND i.[CountryId] = lty.[CountryId]
		JOIN [BinderSection] bs ON b.[Id] = bs.[BinderId] AND @ClassId = bs.[ClassId]
	WHERE i.[PolicyInceptionDate] BETWEEN b.[InceptionDate] AND b.[ExpiryDate]
	ORDER BY 2
	RETURN
END
GO

CREATE PROCEDURE [apiClaimStatus](@ClaimId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Index INT, @Status BIT
	SELECT @Index = [Index], @Status = [Status] FROM [vwClaimStatusCurrent] WHERE [ClaimId] = @ClaimId
	SELECT [Status] = N'0', [StatusDesc] = N'Closed' UNION ALL
	SELECT N'1', CASE WHEN ISNULL(@Index, 0) = 0 THEN N'Open' ELSE N'Reopened' END
	ORDER BY 1 DESC
	RETURN
END
GO

CREATE PROCEDURE [apiClaimSave](
  @IncidentId INT,
		@ClaimantId INT,
		@ClaimId INT = NULL,
		@Title NVARCHAR(255) = NULL,
		@ClassId NVARCHAR(5) = NULL,
		@BinderId INT = NULL,
		@Status BIT = NULL,
		@UserId INT
 )
AS
BEGIN
 SET NOCOUNT ON
	IF @ClaimId IS NULL BEGIN
	 INSERT INTO [Claim] (
		  [IncidentId],
				[ClaimantId],
				[Title],
				[ClassId],
				[BinderId],
				[CreatedDTO],
				[CreatedById],
				[UpdatedDTO],
				[UpdatedById]
		 )
		SELECT
		 [IncidentId] = @IncidentId,
			[ClaimantId] = @ClaimantId,
			[Title] = @Title,
			[ClassId] = @ClassId,
			[BinderId] = @BinderId,
			[CreatedDTO] = GETUTCDATE(),
			[CreatedById] = @UserId,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		SET @ClaimId = SCOPE_IDENTITY()
		-- Set initial status to "Open"
		INSERT INTO [ClaimStatus] ([ClaimId], [Index], [UpdatedDTO], [UpdatedById], [Status])
		VALUES (@ClaimId, 0, GETUTCDATE(), @UserId, 1)
	END ELSE BEGIN
  UPDATE [Claim]
		SET
		 [IncidentId] = @IncidentId,
			[ClaimantId] = @ClaimantId,
			[Title] = @Title,
			[ClassId] = @ClassId,
			[BinderId] = @BinderId,
			[CreatedDTO] = GETUTCDATE(),
			[CreatedById] = @UserId,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		WHERE [Id] = @ClaimId
		-- Update incident status
		INSERT INTO [ClaimStatus] ([ClaimId], [Index], [UpdatedDTO], [UpdatedById], [Status], [PreviousUpdateDTO])
		SELECT
		 [ClaimId],
			[Index] = [Index] + 1,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId,
			[Status] = @Status,
			[PreviousUpdateDTO] = [UpdatedDTO]
		FROM [vwClaimStatusCurrent]
		WHERE [ClaimId] = @ClaimId
		 AND [Status] <> ISNULL(@Status, [Status])
	END
	SELECT [ClaimId] = @ClaimId
	RETURN @ClaimId
END
GO

CREATE PROCEDURE [apiIncidents](@UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [IncidentId] = i.[Id],
		[SysNum] = i.[SysNum],
		[TPA] = tpa.[DisplayName],
		[Coverholder] = cov.[DisplayName],
		[Policyholder] = cmt.[Name],
		[DateIncident] = i.[DateIncident],
		[Status] = CASE c.[Status] WHEN 1 THEN N'Open' WHEN 0 THEN N'Closed' ELSE N'Incident Only' END
	FROM [Incident] i
		JOIN [Company] tpa ON i.[TPAId] = tpa.[Id]
		LEFT JOIN [Company] cov ON i.[CoverholderId] = cov.[Id]
	 LEFT JOIN [Claimant] cmt ON i.[Id] = cmt.[IncidentId] AND i.[PolicyholderId] = cmt.[Id]
		LEFT JOIN (
		  SELECT
				 [IncidentId] = clm.[IncidentId],
					[Status] = CONVERT(BIT, MAX(CONVERT(INT, cst.[Status])))
				FROM [Claim] clm
				 JOIN [vwClaimStatusCurrent] cst ON clm.[Id] = cst.[ClaimId]
				GROUP BY clm.[IncidentId]
		 ) c ON i.[Id] = c.[IncidentId]
	ORDER BY i.[DateIncident] DESC
	RETURN
END
GO



DECLARE @IncidentId INT
EXEC @IncidentId = [apiIncidentSave]
 @BrokerId = 1, @DateBrokerAdvised = N'1996-01-01',
	@TPAId = 1, @DateTPANotified = N'1996-01-02',
	@DateIncident = '1995-12-25', @Description = N'Test Incident #1', @CountryId = N'GB',
	@PolicyholderForename = N'Pierre', @PolicyholderSurname = N'Henry', @PolicyInceptionDate = N'1995-09-01', @PolicyExpiryDate = N'1996-08-31',
	@CoverholderId = 1,
	@UserId = 1
EXEC [apiIncident] @IncidentId, 1

EXEC [apiClaimBinder] 1, N'EMP', 1
