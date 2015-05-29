USE [Advent]
GO

IF OBJECT_ID(N'apiLossFundSave', N'P') IS NOT NULL DROP PROCEDURE [apiLossFundSave]
IF OBJECT_ID(N'apiLossFundTPA', N'P') IS NOT NULL DROP PROCEDURE [apiLossFundTPA]
IF OBJECT_ID(N'apiLossFund', N'P') IS NOT NULL DROP PROCEDURE [apiLossFund]
IF OBJECT_ID(N'apiLossFunds', N'P') IS NOT NULL DROP PROCEDURE [apiLossFunds]
IF OBJECT_ID(N'LossFund', N'U') IS NOT NULL DROP TABLE [LossFund]
IF OBJECT_ID(N'apiCurrencies', N'P') IS NOT NULL DROP PROCEDURE [apiCurrencies]
IF OBJECT_ID(N'Currency', N'U') IS NOT NULL DROP TABLE [Currency]
GO

CREATE TABLE [Currency] (
  [Id] NCHAR(3) NOT NULL,
		[Name] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Currency] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Currency_Name] UNIQUE CLUSTERED ([Name])
	)
GO

INSERT INTO [Currency] ([Id], [Name])
VALUES
 (N'GBP', N'British Pounds'),
	(N'EUR', N'Euros'),
	(N'USD', N'US Dollars')
GO

CREATE PROCEDURE [apiCurrencies](@UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [CurrencyId] = [Id], [Currency] = [Name] FROM [Currency] ORDER BY 2
	RETURN
END
GO

CREATE TABLE [LossFund] (
		[TPAId] INT NOT NULL,
  [Id] INT NOT NULL IDENTITY (1, 1),
		[Name] NVARCHAR(255) NOT NULL,
		[BankCode] NVARCHAR(50) NOT NULL,
		[AccountNum] NVARCHAR(50) NOT NULL,
		[CurrencyId] NCHAR(3) NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_LossFund_Active] DEFAULT (1),
		[CreatedDTO] DATETIMEOFFSET NOT NULL,
		[CreatedById] INT NOT NULL,
		[UpdatedDTO] DATETIMEOFFSET NOT NULL,
		[UpdatedById] INT NOT NULL,
		CONSTRAINT [PK_LossFund] PRIMARY KEY CLUSTERED ([TPAId], [Id]),
		CONSTRAINT [UQ_LossFund_Id] UNIQUE ([Id]),
		CONSTRAINT [UQ_LossFund_Name] UNIQUE ([TPAId], [Name]),
		CONSTRAINT [UQ_LossFund_Account] UNIQUE ([TPAId], [BankCode], [AccountNum], [CurrencyId]),
		CONSTRAINT [FK_LossFund_Company] FOREIGN KEY ([TPAId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_LossFund_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [Currency] ([Id]),
		CONSTRAINT [CK_LossFund_UpdatedDTO] CHECK ([UpdatedDTO] >= [CreatedDTO])
	)
GO

CREATE PROCEDURE [apiLossFunds](@UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [LossFundId] = lf.[Id],
		[TPA] = tpa.[Name],
		[Name] = lf.[Name],
		[AccountNum] = ISNULL(REPLICATE(N'*', LEN(lf.[AccountNum]) - 4), N'') + RIGHT(lf.[AccountNum], 4),
		[Currency] = cu.[Id],
		[Active] = lf.[Active]
	FROM [LossFund] lf
	 JOIN [Company] tpa ON lf.[TPAId] = tpa.[Id]
	 JOIN [Currency] cu ON lf.[CurrencyId] = cu.[Id]
	ORDER BY tpa.[Name], lf.[Name]
	RETURN
END
GO

CREATE PROCEDURE [apiLossFund](@LossFundId INT, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [LossFundId] = [Id],
		[TPAId],
		[Name],
		[BankCode],
		[AccountNum],
		[CurrencyId],
		[Active]
	FROM [LossFund]
	WHERE [Id] = @LossFundId
	RETURN
END
GO

CREATE PROCEDURE [apiLossFundTPA](@LossFundId INT = NULL, @UserId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT
	 [TPAId] = c.[Id],
		[TPA] = c.[DisplayName]
	FROM [Company] c
	 LEFT JOIN [LossFund] lf ON @LossFundId = lf.[Id] AND c.[Id] = lf.[TPAId]
	WHERE c.[TPA] & c.[Active] = 1
	 OR lf.[Id] IS NOT NULL
	ORDER BY c.[DisplayName]
	RETURN
END
GO

CREATE PROCEDURE [apiLossFundSave](
  @LossFundId INT = NULL,
  @TPAId INT,
		@Name NVARCHAR(255),
		@BankCode NVARCHAR(255),
		@AccountNum NVARCHAR(255),
		@CurrencyId NCHAR(3),
		@Active BIT,
		@UserId INT
 )
AS
BEGIN
 SET NOCOUNT ON
	IF @LossFundId IS NULL BEGIN
	 INSERT INTO [LossFund] (
		  [TPAId],
				[Name],
				[BankCode],
				[AccountNum],
				[CurrencyId],
				[Active],
				[CreatedDTO],
				[CreatedById],
				[UpdatedDTO],
				[UpdatedById]
			)
		SELECT
		 [TPAId] = @TPAId,
			[Name] = @Name,
			[BankCode] = @BankCode,
			[AccountNum] = @AccountNum,
			[CurrencyId] = @CurrencyId,
			[Active] = @Active,
			[CreatedDTO] = GETUTCDATE(),
			[CreatedById] = @UserId,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		SET @LossFundId = SCOPE_IDENTITY()
	END ELSE BEGIN
	 UPDATE [LossFund]
		SET
		 [TPAId] = @TPAId,
			[Name] = @Name,
			[BankCode] = @BankCode,
			[AccountNum] = @AccountNum,
			[CurrencyId] = @CurrencyId,
			[Active] = @Active,
			[UpdatedDTO] = GETUTCDATE(),
			[UpdatedById] = @UserId
		WHERE [Id] = @LossFundId
	END
	SELECT [LossFundId] = @LossFundId
	RETURN
	END
GO

--CREATE TABLE [BinderSectionLossFund](
  --[BinderId] INT NOT NULL,
