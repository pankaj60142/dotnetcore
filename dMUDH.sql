
USE [dMUDH]
GO
/****** Object:  Schema [Laimonas.Simutis]    Script Date: 7/7/2020 3:33:54 PM ******/
CREATE SCHEMA [Laimonas.Simutis]
GO
/****** Object:  StoredProcedure [dbo].[dt_addtosourcecontrol]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_addtosourcecontrol]
    @vchSourceSafeINI varchar(255) = '',
    @vchProjectName   varchar(255) ='',
    @vchComment       varchar(255) ='',
    @vchLoginName     varchar(255) ='',
    @vchPassword      varchar(255) =''

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @iStreamObjectId int
select @iStreamObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

declare @vchDatabaseName varchar(255)
select @vchDatabaseName = db_name()

declare @iReturnValue int
select @iReturnValue = 0

declare @iPropertyObjectId int
declare @vchParentId varchar(255)

declare @iObjectCount int
select @iObjectCount = 0

    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError


    /* Create Project in SS */
    exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
											'AddProjectToSourceSafe',
											NULL,
											@vchSourceSafeINI,
											@vchProjectName output,
											@@SERVERNAME,
											@vchDatabaseName,
											@vchLoginName,
											@vchPassword,
											@vchComment


    if @iReturn <> 0 GOTO E_OAError

    /* Set Database Properties */

    begin tran SetProperties

    /* add high level object */

    exec @iPropertyObjectId = dbo.dt_adduserobject_vcs 'VCSProjectID'

    select @vchParentId = CONVERT(varchar(255),@iPropertyObjectId)

    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSProjectID', @vchParentId , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSProject' , @vchProjectName , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSourceSafeINI' , @vchSourceSafeINI , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSQLServer', @@SERVERNAME, NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSQLDatabase', @vchDatabaseName, NULL

    if @@error <> 0 GOTO E_General_Error

    commit tran SetProperties
    
    select @iObjectCount = 0;

CleanUp:
    select @vchProjectName
    select @iObjectCount
    return

E_General_Error:
    /* this is an all or nothing.  No specific error messages */
    goto CleanUp

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_addtosourcecontrol_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_addtosourcecontrol_u]
    @vchSourceSafeINI nvarchar(255) = '',
    @vchProjectName   nvarchar(255) ='',
    @vchComment       nvarchar(255) ='',
    @vchLoginName     nvarchar(255) ='',
    @vchPassword      nvarchar(255) =''

as
	-- This procedure should no longer be called;  dt_addtosourcecontrol should be called instead.
	-- Calls are forwarded to dt_addtosourcecontrol to maintain backward compatibility
	set nocount on
	exec dbo.dt_addtosourcecontrol 
		@vchSourceSafeINI, 
		@vchProjectName, 
		@vchComment, 
		@vchLoginName, 
		@vchPassword







GO
/****** Object:  StoredProcedure [dbo].[dt_adduserobject]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Add an object to the dtproperties table
*/
create procedure [dbo].[dt_adduserobject]
as
	set nocount on
	/*
	** Create the user object if it does not exist already
	*/
	begin transaction
		insert dbo.dtproperties (property) VALUES ('DtgSchemaOBJECT')
		update dbo.dtproperties set objectid=@@identity 
			where id=@@identity and property='DtgSchemaOBJECT'
	commit
	return @@identity





GO
/****** Object:  StoredProcedure [dbo].[dt_adduserobject_vcs]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[dt_adduserobject_vcs]
    @vchProperty varchar(64)

as

set nocount on

declare @iReturn int
    /*
    ** Create the user object if it does not exist already
    */
    begin transaction
        select @iReturn = objectid from dbo.dtproperties where property = @vchProperty
        if @iReturn IS NULL
        begin
            insert dbo.dtproperties (property) VALUES (@vchProperty)
            update dbo.dtproperties set objectid=@@identity
                    where id=@@identity and property=@vchProperty
            select @iReturn = @@identity
        end
    commit
    return @iReturn







GO
/****** Object:  StoredProcedure [dbo].[dt_checkinobject]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_checkinobject]
    @chObjectType  char(4),
    @vchObjectName varchar(255),
    @vchComment    varchar(255)='',
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     Text = '', /* drop stream   */ /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     Text = '', /* create stream */
    @txStream3     Text = ''  /* grant stream  */


as

	set nocount on

	declare @iReturn int
	declare @iObjectId int
	select @iObjectId = 0
	declare @iStreamObjectId int

	declare @VSSGUID varchar(100)
	select @VSSGUID = 'SQLVersionControl.VCS_SQL'

	declare @iPropertyObjectId int
	select @iPropertyObjectId  = 0

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    declare @iReturnValue	  int
    declare @pos			  int
    declare @vchProcLinePiece varchar(255)

    
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        if @iActionFlag = 1
        begin
            /* Procedure Can have up to three streams
            Drop Stream, Create Stream, GRANT stream */

            begin tran compile_all

            /* try to compile the streams */
            exec (@txStream1)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream2)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream3)
            if @@error <> 0 GOTO E_Compile_Fail
        end

        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT
        if @iReturn <> 0 GOTO E_OAError
        
        if @iActionFlag = 1
        begin
            
            declare @iStreamLength int
			
			select @pos=1
			select @iStreamLength = datalength(@txStream2)
			
			if @iStreamLength > 0
			begin
			
				while @pos < @iStreamLength
				begin
						
					select @vchProcLinePiece = substring(@txStream2, @pos, 255)
					
					exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
            		if @iReturn <> 0 GOTO E_OAError
            		
					select @pos = @pos + 255
					
				end
            
				exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
														'CheckIn_StoredProcedure',
														NULL,
														@sProjectName = @vchProjectName,
														@sSourceSafeINI = @vchSourceSafeINI,
														@sServerName = @vchServerName,
														@sDatabaseName = @vchDatabaseName,
														@sObjectName = @vchObjectName,
														@sComment = @vchComment,
														@sLoginName = @vchLoginName,
														@sPassword = @vchPassword,
														@iVCSFlags = @iVCSFlags,
														@iActionFlag = @iActionFlag,
														@sStream = ''
                                        
			end
        end
        else
        begin
        
            select colid, text into #ProcLines
            from syscomments
            where id = object_id(@vchObjectName)
            order by colid

            declare @iCurProcLine int
            declare @iProcLines int
            select @iCurProcLine = 1
            select @iProcLines = (select count(*) from #ProcLines)
            while @iCurProcLine <= @iProcLines
            begin
                select @pos = 1
                declare @iCurLineSize int
                select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
                while @pos <= @iCurLineSize
                begin                
                    select @vchProcLinePiece = convert(varchar(255),
                        substring((select text from #ProcLines where colid = @iCurProcLine),
                                  @pos, 255 ))
                    exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
                    if @iReturn <> 0 GOTO E_OAError
                    select @pos = @pos + 255                  
                end
                select @iCurProcLine = @iCurProcLine + 1
            end
            drop table #ProcLines

            exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
													'CheckIn_StoredProcedure',
													NULL,
													@sProjectName = @vchProjectName,
													@sSourceSafeINI = @vchSourceSafeINI,
													@sServerName = @vchServerName,
													@sDatabaseName = @vchDatabaseName,
													@sObjectName = @vchObjectName,
													@sComment = @vchComment,
													@sLoginName = @vchLoginName,
													@sPassword = @vchPassword,
													@iVCSFlags = @iVCSFlags,
													@iActionFlag = @iActionFlag,
													@sStream = ''
        end

        if @iReturn <> 0 GOTO E_OAError

        if @iActionFlag = 1
        begin
            commit tran compile_all
            if @@error <> 0 GOTO E_Compile_Fail
        end

    end

CleanUp:
	return

E_Compile_Fail:
	declare @lerror int
	select @lerror = @@error
	rollback tran compile_all
	RAISERROR (@lerror,16,-1)
	goto CleanUp

E_OAError:
	if @iActionFlag = 1 rollback tran compile_all
	exec dbo.dt_displayoaerror @iObjectId, @iReturn
	goto CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_checkinobject_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_checkinobject_u]
    @chObjectType  char(4),
    @vchObjectName nvarchar(255),
    @vchComment    nvarchar(255)='',
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     text = '',  /* drop stream   */ /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     text = '',  /* create stream */
    @txStream3     text = ''   /* grant stream  */

as	
	-- This procedure should no longer be called;  dt_checkinobject should be called instead.
	-- Calls are forwarded to dt_checkinobject to maintain backward compatibility.
	set nocount on
	exec dbo.dt_checkinobject
		@chObjectType,
		@vchObjectName,
		@vchComment,
		@vchLoginName,
		@vchPassword,
		@iVCSFlags,
		@iActionFlag,   
		@txStream1,		
		@txStream2,		
		@txStream3		







GO
/****** Object:  StoredProcedure [dbo].[dt_checkoutobject]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_checkoutobject]
    @chObjectType  char(4),
    @vchObjectName varchar(255),
    @vchComment    varchar(255),
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255),
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0/* 0 => Checkout, 1 => GetLatest, 2 => UndoCheckOut */

as

	set nocount on

	declare @iReturn int
	declare @iObjectId int
	select @iObjectId =0

	declare @VSSGUID varchar(100)
	select @VSSGUID = 'SQLVersionControl.VCS_SQL'

	declare @iReturnValue int
	select @iReturnValue = 0

	declare @vchTempText varchar(255)

	/* this is for our strings */
	declare @iStreamObjectId int
	select @iStreamObjectId = 0

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        /* Procedure Can have up to three streams
           Drop Stream, Create Stream, GRANT stream */

        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
												'CheckOut_StoredProcedure',
												NULL,
												@sProjectName = @vchProjectName,
												@sSourceSafeINI = @vchSourceSafeINI,
												@sObjectName = @vchObjectName,
												@sServerName = @vchServerName,
												@sDatabaseName = @vchDatabaseName,
												@sComment = @vchComment,
												@sLoginName = @vchLoginName,
												@sPassword = @vchPassword,
												@iVCSFlags = @iVCSFlags,
												@iActionFlag = @iActionFlag

        if @iReturn <> 0 GOTO E_OAError


        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #commenttext (id int identity, sourcecode varchar(255))


        select @vchTempText = 'STUB'
        while @vchTempText is not null
        begin
            exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError
            
            if (@vchTempText = '') set @vchTempText = null
            if (@vchTempText is not null) insert into #commenttext (sourcecode) select @vchTempText
        end

        select 'VCS'=sourcecode from #commenttext order by id
        select 'SQL'=text from syscomments where id = object_id(@vchObjectName) order by colid

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_checkoutobject_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_checkoutobject_u]
    @chObjectType  char(4),
    @vchObjectName nvarchar(255),
    @vchComment    nvarchar(255),
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255),
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0/* 0 => Checkout, 1 => GetLatest, 2 => UndoCheckOut */

as

	-- This procedure should no longer be called;  dt_checkoutobject should be called instead.
	-- Calls are forwarded to dt_checkoutobject to maintain backward compatibility.
	set nocount on
	exec dbo.dt_checkoutobject
		@chObjectType,  
		@vchObjectName, 
		@vchComment,    
		@vchLoginName,  
		@vchPassword,  
		@iVCSFlags,    
		@iActionFlag 







GO
/****** Object:  StoredProcedure [dbo].[dt_displayoaerror]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dt_displayoaerror]
    @iObject int,
    @iresult int
as

set nocount on

declare @vchOutput      varchar(255)
declare @hr             int
declare @vchSource      varchar(255)
declare @vchDescription varchar(255)

    exec @hr = master.dbo.sp_OAGetErrorInfo @iObject, @vchSource OUT, @vchDescription OUT

    select @vchOutput = @vchSource + ': ' + @vchDescription
    raiserror (@vchOutput,16,-1)

    return






GO
/****** Object:  StoredProcedure [dbo].[dt_displayoaerror_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dt_displayoaerror_u]
    @iObject int,
    @iresult int
as
	-- This procedure should no longer be called;  dt_displayoaerror should be called instead.
	-- Calls are forwarded to dt_displayoaerror to maintain backward compatibility.
	set nocount on
	exec dbo.dt_displayoaerror
		@iObject,
		@iresult







GO
/****** Object:  StoredProcedure [dbo].[dt_droppropertiesbyid]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Drop one or all the associated properties of an object or an attribute 
**
**	dt_dropproperties objid, null or '' -- drop all properties of the object itself
**	dt_dropproperties objid, property -- drop the property
*/
create procedure [dbo].[dt_droppropertiesbyid]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		delete from dbo.dtproperties where objectid=@id
	else
		delete from dbo.dtproperties 
			where objectid=@id and property=@property






GO
/****** Object:  StoredProcedure [dbo].[dt_dropuserobjectbyid]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Drop an object from the dbo.dtproperties table
*/
create procedure [dbo].[dt_dropuserobjectbyid]
	@id int
as
	set nocount on
	delete from dbo.dtproperties where objectid=@id





GO
/****** Object:  StoredProcedure [dbo].[dt_generateansiname]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
**	Generate an ansi name that is unique in the dtproperties.value column 
*/ 
create procedure [dbo].[dt_generateansiname](@name varchar(255) output) 
as 
	declare @prologue varchar(20) 
	declare @indexstring varchar(20) 
	declare @index integer 
 
	set @prologue = 'MSDT-A-' 
	set @index = 1 
 
	while 1 = 1 
	begin 
		set @indexstring = cast(@index as varchar(20)) 
		set @name = @prologue + @indexstring 
		if not exists (select value from dtproperties where value = @name) 
			break 
		 
		set @index = @index + 1 
 
		if (@index = 10000) 
			goto TooMany 
	end 
 
Leave: 
 
	return 
 
TooMany: 
 
	set @name = 'DIAGRAM' 
	goto Leave 





GO
/****** Object:  StoredProcedure [dbo].[dt_getobjwithprop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve the owner object(s) of a given property
*/
create procedure [dbo].[dt_getobjwithprop]
	@property varchar(30),
	@value varchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@value is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and value=@value





GO
/****** Object:  StoredProcedure [dbo].[dt_getobjwithprop_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve the owner object(s) of a given property
*/
create procedure [dbo].[dt_getobjwithprop_u]
	@property varchar(30),
	@uvalue nvarchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@uvalue is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and uvalue=@uvalue





GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure [dbo].[dt_getpropertiesbyid]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property





GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure [dbo].[dt_getpropertiesbyid_u]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property





GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid_vcs]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[dt_getpropertiesbyid_vcs]
    @id       int,
    @property varchar(64),
    @value    varchar(255) = NULL OUT

as

    set nocount on

    select @value = (
        select value
                from dbo.dtproperties
                where @id=objectid and @property=property
                )






GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid_vcs_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[dt_getpropertiesbyid_vcs_u]
    @id       int,
    @property varchar(64),
    @value    nvarchar(255) = NULL OUT

as

    -- This procedure should no longer be called;  dt_getpropertiesbyid_vcsshould be called instead.
	-- Calls are forwarded to dt_getpropertiesbyid_vcs to maintain backward compatibility.
	set nocount on
    exec dbo.dt_getpropertiesbyid_vcs
		@id,
		@property,
		@value output






GO
/****** Object:  StoredProcedure [dbo].[dt_isundersourcecontrol]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_isundersourcecontrol]
    @vchLoginName varchar(255) = '',
    @vchPassword  varchar(255) = '',
    @iWhoToo      int = 0 /* 0 => Just check project; 1 => get list of objs */

as

	set nocount on

	declare @iReturn int
	declare @iObjectId int
	select @iObjectId = 0

	declare @VSSGUID varchar(100)
	select @VSSGUID = 'SQLVersionControl.VCS_SQL'

	declare @iReturnValue int
	select @iReturnValue = 0

	declare @iStreamObjectId int
	select @iStreamObjectId   = 0

	declare @vchTempText varchar(255)

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if (@vchProjectName = '')	set @vchProjectName		= null
    if (@vchSourceSafeINI = '') set @vchSourceSafeINI	= null
    if (@vchServerName = '')	set @vchServerName		= null
    if (@vchDatabaseName = '')	set @vchDatabaseName	= null
    
    if (@vchProjectName is null) or (@vchSourceSafeINI is null) or (@vchServerName is null) or (@vchDatabaseName is null)
    begin
        RAISERROR('Not Under Source Control',16,-1)
        return
    end

    if @iWhoToo = 1
    begin

        /* Get List of Procs in the project */
        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
												'GetListOfObjects',
												NULL,
												@vchProjectName,
												@vchSourceSafeINI,
												@vchServerName,
												@vchDatabaseName,
												@vchLoginName,
												@vchPassword

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #ObjectList (id int identity, vchObjectlist varchar(255))

        select @vchTempText = 'STUB'
        while @vchTempText is not null
        begin
            exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError
            
            if (@vchTempText = '') set @vchTempText = null
            if (@vchTempText is not null) insert into #ObjectList (vchObjectlist ) select @vchTempText
        end

        select vchObjectlist from #ObjectList order by id
    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_isundersourcecontrol_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_isundersourcecontrol_u]
    @vchLoginName nvarchar(255) = '',
    @vchPassword  nvarchar(255) = '',
    @iWhoToo      int = 0 /* 0 => Just check project; 1 => get list of objs */

as
	-- This procedure should no longer be called;  dt_isundersourcecontrol should be called instead.
	-- Calls are forwarded to dt_isundersourcecontrol to maintain backward compatibility.
	set nocount on
	exec dbo.dt_isundersourcecontrol
		@vchLoginName,
		@vchPassword,
		@iWhoToo 







GO
/****** Object:  StoredProcedure [dbo].[dt_removefromsourcecontrol]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[dt_removefromsourcecontrol]

as

    set nocount on

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    exec dbo.dt_droppropertiesbyid @iPropertyObjectId, null

    /* -1 is returned by dt_droppopertiesbyid */
    if @@error <> 0 and @@error <> -1 return 1

    return 0







GO
/****** Object:  StoredProcedure [dbo].[dt_setpropertybyid]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		value -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure [dbo].[dt_setpropertybyid]
	@id int,
	@property varchar(64),
	@value varchar(255),
	@lvalue image
as
	set nocount on
	declare @uvalue nvarchar(255) 
	set @uvalue = convert(nvarchar(255), @value) 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@value, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @value, @uvalue, @lvalue)
	end






GO
/****** Object:  StoredProcedure [dbo].[dt_setpropertybyid_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		uvalue -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure [dbo].[dt_setpropertybyid_u]
	@id int,
	@property varchar(64),
	@uvalue nvarchar(255),
	@lvalue image
as
	set nocount on
	-- 
	-- If we are writing the name property, find the ansi equivalent. 
	-- If there is no lossless translation, generate an ansi name. 
	-- 
	declare @avalue varchar(255) 
	set @avalue = null 
	if (@uvalue is not null) 
	begin 
		if (convert(nvarchar(255), convert(varchar(255), @uvalue)) = @uvalue) 
		begin 
			set @avalue = convert(varchar(255), @uvalue) 
		end 
		else 
		begin 
			if 'DtgSchemaNAME' = @property 
			begin 
				exec dbo.dt_generateansiname @avalue output 
			end 
		end 
	end 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@avalue, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @avalue, @uvalue, @lvalue)
	end





GO
/****** Object:  StoredProcedure [dbo].[dt_validateloginparams]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_validateloginparams]
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255)
as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchSourceSafeINI varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT

    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
											'ValidateLoginParams',
											NULL,
											@sSourceSafeINI = @vchSourceSafeINI,
											@sLoginName = @vchLoginName,
											@sPassword = @vchPassword
    if @iReturn <> 0 GOTO E_OAError

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_validateloginparams_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_validateloginparams_u]
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)
as

	-- This procedure should no longer be called;  dt_validateloginparams should be called instead.
	-- Calls are forwarded to dt_validateloginparams to maintain backward compatibility.
	set nocount on
	exec dbo.dt_validateloginparams
		@vchLoginName,
		@vchPassword 







GO
/****** Object:  StoredProcedure [dbo].[dt_vcsenabled]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_vcsenabled]

as

set nocount on

declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iReturn int
    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 raiserror('', 16, -1) /* Can't Load Helper DLLC */







GO
/****** Object:  StoredProcedure [dbo].[dt_verstamp006]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	This procedure returns the version number of the stored
**    procedures used by legacy versions of the Microsoft
**	Visual Database Tools.  Version is 7.0.00.
*/
create procedure [dbo].[dt_verstamp006]
as
	select 7000





GO
/****** Object:  StoredProcedure [dbo].[dt_verstamp007]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	This procedure returns the version number of the stored
**    procedures used by the the Microsoft Visual Database Tools.
**	Version is 7.0.05.
*/
create procedure [dbo].[dt_verstamp007]
as
	select 7005





GO
/****** Object:  StoredProcedure [dbo].[dt_whocheckedout]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_whocheckedout]
        @chObjectType  char(4),
        @vchObjectName varchar(255),
        @vchLoginName  varchar(255),
        @vchPassword   varchar(255)

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        declare @vchReturnValue varchar(255)
        select @vchReturnValue = ''

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
												'WhoCheckedOut',
												@vchReturnValue OUT,
												@sProjectName = @vchProjectName,
												@sSourceSafeINI = @vchSourceSafeINI,
												@sObjectName = @vchObjectName,
												@sServerName = @vchServerName,
												@sDatabaseName = @vchDatabaseName,
												@sLoginName = @vchLoginName,
												@sPassword = @vchPassword

        if @iReturn <> 0 GOTO E_OAError

        select @vchReturnValue

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp







GO
/****** Object:  StoredProcedure [dbo].[dt_whocheckedout_u]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[dt_whocheckedout_u]
        @chObjectType  char(4),
        @vchObjectName nvarchar(255),
        @vchLoginName  nvarchar(255),
        @vchPassword   nvarchar(255)

as

	-- This procedure should no longer be called;  dt_whocheckedout should be called instead.
	-- Calls are forwarded to dt_whocheckedout to maintain backward compatibility.
	set nocount on
	exec dbo.dt_whocheckedout
		@chObjectType, 
		@vchObjectName,
		@vchLoginName, 
		@vchPassword  







GO
/****** Object:  StoredProcedure [dbo].[Installations_Insert_XXX]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Installations_Insert_XXX]
	(
		@ServerID int,
		@ApplicationID int
	)
AS

INSERT INTO Installations(
	ServerID, ApplicationID)
VALUES(
	@ServerID, @ApplicationID)
	
SELECT scope_identity()

RETURN





GO
/****** Object:  StoredProcedure [dbo].[lkpSPServerData]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[lkpSPServerData] 

@Name VARCHAR(50)

AS

SELECT Name FROM Server
WHERE name = @Name




GO
/****** Object:  StoredProcedure [dbo].[Server_XXX]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Server_XXX]
/*
	(
		@parameter1 datatype = default value,
		@parameter2 datatype OUTPUT
	)
*/
AS
	/* SET NOCOUNT ON */
	RETURN





GO
/****** Object:  StoredProcedure [dbo].[Servers_Delete_XXX]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Servers_Delete_XXX]
	(
		@ServerID int
	)
AS

DELETE FROM
	Installations
WHERE
	ServerID = @ServerID

DELETE FROM
	Servers
WHERE
	ServerID = @ServerID


RETURN





GO
/****** Object:  StoredProcedure [dbo].[Servers_Insert_XXX]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Servers_Insert_XXX]
	(
		@Name varchar(150),
		@Type int,
		@IPAddress varchar(150),
		@AdminEngineer varchar(150),
		@IIS bit,
		@SoftwareSpecs varchar(150),
		@HardwareSpecs varchar(150),
		@DBAAssigned varchar(150),
		@DBMS varchar(150),
		@InstallationSpecialInstructions varchar(150),
		@Location varchar(150),
		@BackupSchedule varchar(150),
		@StartupInstructions varchar(150),
		@ShutdownInstructions varchar(150)
	)
AS

INSERT INTO Servers(
	[Name],
	Type,
	IPAddress,
	AdminEngineer,
	IIS,
	SoftwareSpecs,
	HardwareSpecs,
	DBAAssigned,
	DBMS,
	InstallationSpecialInstructions,
	Location,
	BackupSchedule,
	StartupInstructions,
	ShutdownInstructions
)
VALUES(
	@Name,
	@Type,
	@IPAddress,
	@AdminEngineer,
	@IIS,
	@SoftwareSpecs,
	@HardwareSpecs,
	@DBAAssigned,
	@DBMS,
	@InstallationSpecialInstructions,
	@Location,
	@BackupSchedule,
	@StartupInstructions,
	@ShutdownInstructions
)

SELECT scope_identity()


RETURN





GO
/****** Object:  StoredProcedure [dbo].[Servers_Update_XXX]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Servers_Update_XXX]
	(
		@ServerID int,
		@Name varchar(150),
		@Type int,
		@IPAddress varchar(150),
		@AdminEngineer varchar(150),
		@IIS bit,
		@SoftwareSpecs varchar(150),
		@HardwareSpecs varchar(150),
		@DBAAssigned varchar(150),
		@DBMS varchar(150),
		@InstallationSpecialInstructions varchar(150),
		@Location varchar(150),
		@BackupSchedule varchar(150),
		@StartupInstructions varchar(150),
		@ShutdownInstructions varchar(150)
	)
AS

UPDATE Servers SET
	[Name] = @Name,
	Type = @Type,
	IPAddress = @IPAddress,
	AdminEngineer = @AdminEngineer,
	IIS = @IIS,
	SoftwareSpecs = @SoftwareSpecs,
	HardwareSpecs = @HardwareSpecs,
	DBAAssigned = @DBAAssigned,
	DBMS = @DBMS,
	InstallationSpecialInstructions = @InstallationSpecialInstructions,
	Location = @Location,
	BackupSchedule = @BackupSchedule,
	StartupInstructions = @StartupInstructions,
	ShutdownInstructions = @ShutdownInstructions
WHERE
	ServerID = @ServerID

RETURN





GO
/****** Object:  StoredProcedure [dbo].[usp_AddApplicationToDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_AddApplicationToDatabase]
(
	@DatabaseID INT,
	@ApplicationID INT
)
AS
BEGIN
	
	INSERT INTO ApplicationDatabase
	VALUES (@ApplicationID, @DatabaseID)
	
END





GO
/****** Object:  StoredProcedure [dbo].[usp_AddDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_AddDatabase]
(
	@ServerID INT,
	@DatabaseID INT
)
AS
BEGIN
	INSERT INTO ServerDatabase VALUES (@ServerID, @DatabaseID)
END





GO
/****** Object:  StoredProcedure [dbo].[usp_AddDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_AddDocument]
(
	@DocumentID INT,
	@TypeID INT,
	@ParentID INT
)
AS
BEGIN
	
	-- typeid server=0, app=1, database=2, comm=3
	IF @TypeID = 0 
	BEGIN
		INSERT INTO ServerDocument (ServerID, DocumentID) VALUES (@ParentID, @DocumentID)
	END
	ELSE IF @TypeID = 1
	BEGIN
		INSERT INTO ApplicationDocument (ApplicationID, DocumentID) VALUES (@ParentID, @DocumentID)
	END
	ELSE IF @TypeID = 2
	BEGIN
		INSERT INTO DatabaseDocument (DatabaseID, DocumentID) VALUES (@ParentID, @DocumentID)
	END
	ELSE IF @TypeID = 3
	BEGIN
		INSERT INTO CommunityDocument (CommunityID, DocumentID) VALUES (@ParentID, @DocumentID)
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_Application_Delete]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_Delete
**		Desc: Delete a record in the Applications table and auxillary tables
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_Delete]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON

DECLARE @ReturnCode INTEGER
SET @ReturnCode = 0

BEGIN TRAN

DELETE FROM ApplicationDocuments
WHERE ApplicationID = @ApplicationID
SELECT @ReturnCode = @@ERROR

IF @ReturnCode = 0
	BEGIN
		DELETE FROM Installations
		WHERE ApplicationID = @ApplicationID
		SELECT @ReturnCode = @@ERROR
	END

IF @ReturnCode = 0
	BEGIN
		DELETE FROM Applications
		WHERE ApplicationID = @ApplicationID
	END

IF @ReturnCode = 0
	BEGIN
		COMMIT TRAN
	END
ELSE
	BEGIN
		ROLLBACK TRAN
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_DeleteByServerID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************
	Name:		usp_Application_DeleteByServerID
	Desc:		

	Author:		Alvin Ross
	Created Date:	9-15-2005
	
	History: 
 
	Who:			When:		What:
	------------------------------------------------------------------------------

*******************************************************************/
CREATE Procedure [dbo].[usp_Application_DeleteByServerID]
(
@ServerID int
)
AS

SET NOCOUNT ON

DELETE FROM Installations
Where ServerID = @ServerID







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_DeleteDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_DeleteDocument
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/15/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_DeleteDocument]
(
@DocID INTEGER
)
AS

SET NOCOUNT ON
	
DELETE FROM ApplicationDocuments
WHERE DocID = @DocID






GO
/****** Object:  StoredProcedure [dbo].[usp_Application_Insert]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_Insert
**		Desc: Insert a record into the Application table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_Insert]
(
@Name VARCHAR(50) = NULL,
@Version VARCHAR(25) = NULL,
@InstallerNames VARCHAR(250) = NULL,
@DateInstalled DATETIME = NULL,
@User VARCHAR(100) = NULL,
@User2 VARCHAR(100) = NULL,
@UserContactInfo VARCHAR(200) = NULL,
@User2ContactInfo VARCHAR(200) = NULL,
@VendorName VARCHAR(75) = NULL,
@VendorContact VARCHAR(75) = NULL,
@VendorContactInfo VARCHAR(200) = NULL,
@SupportContact VARCHAR(75) = NULL,
@SupportContactInfo VARCHAR(75) = NULL,
@SupportContactExpirationDate DATETIME = NULL,
@NotesComments VARCHAR(2000) = NULL,
@NewApplicationID INTEGER OUTPUT
)
AS

SET NOCOUNT ON
	
INSERT INTO Applications
(
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
)
VALUES 
(
@Name,
@Version,
@InstallerNames,
@DateInstalled,
@User,
@User2,
@UserContactInfo,
@User2ContactInfo,
@VendorName,
@VendorContact,
@VendorContactInfo,
@SupportContact,
@SupportContactInfo,
@SupportContactExpirationDate,
@NotesComments
)

SELECT @NewApplicationID = @@IDENTITY







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_InsertDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************
	Name:		usp_Application_InsertDocument
	Desc:		

	Author:		Catalyst Software Solutions - Arnold Smith
	Created Date:	9-15-2005
	
	History: 
 
	Who:			When:		What:
	------------------------------------------------------------------------------
	
*******************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_InsertDocument]
(
@ApplicationID INTEGER,
@DocName VARCHAR(200),
@DocPath VARCHAR(255)
)
AS

SET NOCOUNT ON

INSERT INTO ApplicationDocuments
(
ApplicationID,
DocName,
DocPath
) 
VALUES 
(
@ApplicationID,
@DocName,
@DocPath
)







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_InsertServers]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_InsertServers
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/19/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_InsertServers]
(
@ApplicationID INT,
@ServerArray CHAR(4096)
)
AS

SET NOCOUNT ON

DECLARE @intPrevIndex INT
DECLARE @intIndex INT
DECLARE @intTotalLen INT
DECLARE @intLen INT
DECLARE @strData VARCHAR(10)
DECLARE @intData INT
DECLARE @intLengthCount INT
DECLARE @ReturnCode INT

SET @intPrevIndex = 1
SET @intIndex = 0
SET @ReturnCode = 0

--Find the actual length of data passed in stream
SET @intTotalLen = LEN(RTRIM(@ServerArray)) 
SET @intLengthCount = 0
SET @intLen = 0

DELETE FROM Installations
WHERE ApplicationID = @ApplicationID

SELECT @ReturnCode = @@ERROR

WHILE (@intLengthCount < @intTotalLen) AND @ReturnCode = 0
	BEGIN
		--if @intIndex is 0, then no delimiter was found
		SELECT @intIndex = CHARINDEX(',', @ServerArray, @intPrevIndex) 

		IF @intIndex > 0
			BEGIN
				-- the length of the data to extract
				SET @intLen = @intIndex - @intPrevIndex
				SET @strData = SUBSTRING(@ServerArray, @intPrevIndex, @intLen)
				SELECT @strData = LTRIM(RTRIM(@strData)) 

				IF LEN(@strData) > 0
					BEGIN
						SELECT @intData = CAST(@strData AS INT)

						INSERT INTO Installations (
							ApplicationID, 
							ServerID)
						VALUES  (
							@ApplicationID,
							@intData)
					END
				
				 --get position after delimiter
				SET @intPrevIndex = @intIndex + 1
				SET @intLengthCount = @intLengthCount + @intLen + 1
			END
		ELSE	--This will either be the first record of just one ID in the array OR the last record of more than one ID in the array
			BEGIN
				SET @strData = SUBSTRING(@ServerArray, @intPrevIndex, 20)
				SELECT @strData = LTRIM(RTRIM(@strData)) 

				IF LEN(@strData) > 0
					BEGIN
						SELECT @intData = CAST(@strData AS INT)

						INSERT INTO Installations (
							ApplicationID, 
							ServerID)
						VALUES  (
							@ApplicationID,
							@intData)
					END
				
				SET @intLengthCount = @intLengthCount + @intTotalLen + 1
			END				
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_LookForDuplicateName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_LookForDuplicateName
**		Desc: Check if the Name already exists on a record.
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/23/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_LookForDuplicateName]
(
@Name VARCHAR(150),
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON

IF @ApplicationID > 0
	BEGIN	
		SELECT Count(*)
		FROM Applications
		WHERE [Name] = @Name
		AND ApplicationID <> @ApplicationID
	END
ELSE
	BEGIN
		SELECT Count(*)
		FROM Applications
		WHERE [Name] = @Name
	END






GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectAll
**		Desc: Select all records from the Applications table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectAll]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
ApplicationID,
dbo.udf_ServerForApp(ApplicationID, @ServerID) AS ApplicationServerRelation,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications
ORDER BY ApplicationServerRelation DESC, [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectByCriteria
**		Desc: Select all records from the Applications table by criteria
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/19/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectByCriteria]
(
@Name VARCHAR(150) = '%',
@Version VARCHAR(150) = '%',
@VendorName VARCHAR(150) = '%',
@SupportContact VARCHAR(150) = '%'
)
AS

SET NOCOUNT ON
	
SELECT
ApplicationID,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications
WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)
AND (Version LIKE '%' + @Version + '%' OR Version IS NULL)
AND (VendorName LIKE '%' + @VendorName + '%' OR VendorName IS NULL)
AND (SupportContact LIKE '%' + @SupportContact + '%' OR SupportContact IS NULL)
ORDER BY [Name]






GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectByID
**		Desc: Select a record from the Applications table by ApplicationID
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectByID]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
ApplicationID,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications
WHERE ApplicationID = @ApplicationID
ORDER BY [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectByName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectByName
**		Desc: Select records from the Applications table by Name
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectByName]
(
@Name VARCHAR(50)
)
AS

SET NOCOUNT ON
	
SELECT
ApplicationID,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications
WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectDocuments]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectDocuments
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/15/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectDocuments]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
DocID, 
DocName, 
DocPath 
FROM ApplicationDocuments
WHERE ApplicationID = @ApplicationID
ORDER BY DocName






GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectForServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectForServer
**		Desc: Select all Applications records for a server
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectForServer]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
Applications.ApplicationID,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications, Installations
WHERE Applications.ApplicationID = Installations.ApplicationID
AND ServerID = @ServerID
ORDER BY [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_SelectNotForServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_SelectNotForServer
**		Desc: Select all Applications records not already associated with a server
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_SelectNotForServer]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
Applications.ApplicationID,
[Name],
Version,
InstallerNames,
DateInstalled,
[User],
User2,
UserContactInfo,
User2ContactInfo,
VendorName,
VendorContact,
VendorContactInfo,
SupportContact,
SupportContactInfo,
SupportContactExpirationDate,
NotesComments
FROM Applications, Installations
WHERE Applications.ApplicationID = Installations.ApplicationID
AND ServerID <> @ServerID
ORDER BY [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Application_Update]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Application_Update
**		Desc: Update a record in the Application table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Application_Update]
(
@ApplicationID INTEGER,
@Name VARCHAR(50) = NULL,
@Version VARCHAR(25) = NULL,
@InstallerNames VARCHAR(250) = NULL,
@DateInstalled VARCHAR(10) = NULL,
@User VARCHAR(100) = NULL,
@User2 VARCHAR(100) = NULL,
@UserContactInfo VARCHAR(200) = NULL,
@User2ContactInfo VARCHAR(200) = NULL,
@VendorName VARCHAR(75) = NULL,
@VendorContact VARCHAR(75) = NULL,
@VendorContactInfo VARCHAR(200) = NULL,
@SupportContact VARCHAR(75) = NULL,
@SupportContactInfo VARCHAR(75) = NULL,
@SupportContactExpirationDate VARCHAR(10) = NULL,
@NotesComments VARCHAR(2000) = NULL
)
AS

SET NOCOUNT ON

IF @DateInstalled = ''
	BEGIN
		SET @DateInstalled = NULL
	END

IF @SupportContactExpirationDate = ''
	BEGIN
		SET @SupportContactExpirationDate = NULL
	END

UPDATE Applications
SET
[Name] = @Name,
Version = @Version,
InstallerNames = @InstallerNames,
DateInstalled = @DateInstalled,
[User] = @User,
User2 = @User2,
UserContactInfo = @UserContactInfo,
User2ContactInfo = @User2ContactInfo,
VendorName = @VendorName,
VendorContact = @VendorContact,
VendorContactInfo = @VendorContactInfo,
SupportContact = @SupportContact,
SupportContactInfo = @SupportContactInfo,
SupportContactExpirationDate = @SupportContactExpirationDate,
NotesComments = @NotesComments
WHERE ApplicationID = @ApplicationID







GO
/****** Object:  StoredProcedure [dbo].[usp_ApplicationSelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_ApplicationSelectByCriteria]
(
	@ApplicationName VARCHAR(150) = '%',
	@CompanyName VARCHAR(150) = '%',
	@TypeID INT = 0,
	@ShortDescription VARCHAR(255) = '%'
)

AS
BEGIN

	SET NOCOUNT ON

IF @CompanyName = ''
BEGIN
	SELECT 
		ApplicationID,
		Name,
		case developertypeid when 1 then CompanyName else 'GGP' end as 'CompanyName',
		IsNull(lkpAppType.Description, '')  as ApplicationType,
		ShortDescription,
		LongDescription
	FROM Application
	LEFT JOIN lkpAppType (NOLOCK) ON ApplicationTypeID = lkpAppType.LookupID
	LEFT JOIN OutsideDeveloper od (NOLOCK) ON DeveloperID = od.OutsideDeveloperID
	WHERE IsNull(Name, '') LIKE '%' + @ApplicationName + '%'
	AND (ApplicationTypeID = CASE @TypeID WHEN 0 THEN ApplicationTypeID ELSE @TypeID END)
	AND IsNull(ShortDescription, '') LIKE '%' + @ShortDescription + '%'
	ORDER BY Name
END
ELSE
BEGIN
	SELECT 
		ApplicationID,
		Name,
		case developertypeid when 1 then CompanyName else 'GGP' end as 'CompanyName',
		IsNull(lkpAppType.Description, '')  as ApplicationType,
		ShortDescription,
		LongDescription
	FROM Application
	LEFT JOIN lkpAppType (NOLOCK) ON ApplicationTypeID = lkpAppType.LookupID
	LEFT JOIN OutsideDeveloper od (NOLOCK) ON DeveloperID = od.OutsideDeveloperID
	WHERE IsNull(Name, '') LIKE '%' + @ApplicationName + '%'
	AND DeveloperTypeID = 1
	AND od.CompanyName LIKE '%' + @CompanyName + '%'
	AND (ApplicationTypeID = CASE @TypeID WHEN 0 THEN ApplicationTypeID ELSE @TypeID END)
	AND IsNull(ShortDescription, '') LIKE '%' + @ShortDescription + '%'
	ORDER BY Name
END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_CommunitySelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_CommunitySelectByCriteria]
(
	@CommunityName VARCHAR(150) = '%',
	@CommunityTypeID INT = 0
)
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		CommunityID,
		Name,
		Description,
		URL
	FROM Community
	WHERE IsNull(Name, '') LIKE '%' + @CommunityName + '%'
	AND (CommunityTypeID = CASE @CommunityTypeID WHEN 0 THEN CommunityTypeID ELSE @CommunityTypeID END)
	ORDER BY Name

END





GO
/****** Object:  StoredProcedure [dbo].[usp_DatabaseSelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_DatabaseSelectByCriteria]
(
	@DatabaseName VARCHAR(150) = '%',
	@ServerName VARCHAR(255) = '%'
)

AS
BEGIN

	SET NOCOUNT ON

	IF (@ServerName = '%' OR @ServerName = '')
	BEGIN
		SELECT 
			DatabaseID,
			Name as DatabaseName,
			lkpDatabaseType.Description as DatabaseType,
			case when IsDevDB = 1 then 'Dev' when IsTestDB = 1 then 'Test' when IsProdDB = 1 then 'Prod' else 'Error' end as 'DatabaseEnviron'
			--lkpDBA.Description as DBAAssigned
		FROM Databases		
		LEFT JOIN lkpDatabaseType (NOLOCK) ON DBTypeID = lkpDatabaseType.LookupID
		WHERE IsNull(Name, '') LIKE '%' + @DatabaseName + '%'		

		ORDER BY Name
	END
	ELSE
	BEGIN
		SELECT 
			DatabaseID,
			Name as DatabaseName,
			lkpDatabaseType.Description as DatabaseType,
			case when IsDevDB = 1 then 'Dev' when IsTestDB = 1 then 'Test' when IsProdDB = 1 then 'Prod' else 'Error' end as 'DatabaseEnviron'
			--lkpDBA.Description as DBAAssigned
		FROM Databases
		LEFT JOIN lkpDatabaseType (NOLOCK) ON DBTypeID = lkpDatabaseType.LookupID
		WHERE IsNull(Name, '') LIKE '%' + @DatabaseName + '%'
		AND DatabaseID IN (select sd.databaseid from serverdatabase sd join server s on s.serverid = sd.serverid where s.name like @servername)
		ORDER BY Name
	END

END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteADGroup]
	@ADGroupID INT
AS
BEGIN
		DELETE FROM ADGroup WHERE ADGroupID = @ADGroupID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteADGroupsForApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_DeleteADGroupsForApplication]
(
	@ApplicationID INT
)
as
begin
	
	DELETE FROM ADGroup
	WHERE ADGroupID IN
	(SELECT ADGroupID FROM ApplicationADGroup WHERE ApplicationID = @ApplicationID)
end





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DeleteApplication]
	@ApplicationID INT
AS
BEGIN
		DELETE FROM Application WHERE ApplicationID = @ApplicationID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteApplicationADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[usp_DeleteApplicationADGroup]
(
	@ApplicationID INT,
	@ADGroupID INT
)
AS
BEGIN

	DELETE FROM ApplicationADGroup WHERE ApplicationID = @ApplicationID
	AND ADGroupID = @ADGroupID

END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteApplicationContacts]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[usp_DeleteApplicationContacts]
(
	@ApplicationID INT
)
AS
BEGIN
	DELETE FROM Contact WHERE ContactID IN
	(SELECT ContactID FROM ApplicationContact WHERE ApplicationID = @ApplicationID)
END






GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteComment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteComment]
	@CommentID INT
AS
BEGIN
		DELETE FROM Comment WHERE CommentID = @CommentID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteCommunity]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteCommunity]
	@CommunityID INT
AS
BEGIN
		DELETE FROM Community WHERE CommunityID = @CommunityID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteCommunityADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create PROC [dbo].[usp_DeleteCommunityADGroup]
(
	@CommunityID INT,
	@ADGroupID INT
)
AS
BEGIN

	DELETE FROM CommunityADGroup WHERE CommunityID = @CommunityID
	AND ADGroupID = @ADGroupID

END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteContact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteContact]
	@ContactID INT
AS
BEGIN
		DELETE FROM Contact WHERE ContactID = @ContactID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteDatabase]
	@DatabaseID INT
AS
BEGIN
		DELETE FROM Databases WHERE DatabaseID = @DatabaseID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteDesktop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteDesktop]
	@DesktopID INT
AS
BEGIN
		DELETE FROM Desktop WHERE DesktopID = @DesktopID
END




GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteDesktopADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[usp_DeleteDesktopADGroup]
(
	@DesktopID INT,
	@ADGroupID INT
)
AS
BEGIN

	DELETE FROM DesktopADGroup WHERE DesktopID = @DesktopID
	AND ADGroupID = @ADGroupID

END




GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DeleteDocument]
	@DocumentID INT,
	@TypeID INT
AS
BEGIN
		DELETE FROM Document WHERE DocumentID = @DocumentID

		IF @TypeID = 0
		BEGIN
			DELETE FROM ServerDocument WHERE DocumentID = @DocumentID
		END
		ELSE IF @TypeID = 1
		BEGIN 
			DELETE FROM ApplicationDocument WHERE DocumentID = @DocumentID
		END
		ELSE IF @TypeID = 2
		BEGIN 
			DELETE FROM DatabaseDocument WHERE DocumentID = @DocumentID
		END
		ELSE IF @TypeID = 3
		BEGIN 
			DELETE FROM CommunityDocument WHERE DocumentID = @DocumentID
		END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteGGPDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteGGPDeveloper]
	@GGPDeveloperID INT
AS
BEGIN
		DELETE FROM GGPDeveloper WHERE GGPDeveloperID = @GGPDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteInstallation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DeleteInstallation]
	@ServerID INT
AS
BEGIN
		DELETE FROM Installation WHERE ServerID = @ServerID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteLookupItem]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/**************************************************************************
    PROCEDURE:      dbo.usp_DeleteLookupItem
    AUTHOR:         Laimonas Simutis
    CREATE DATE:    07/26/2006
    PURPOSE:        Return all rows from a lookup table.
    INPUT:          
    OUTPUT:         
    HISTORY:        
    TEST:           usp_DeleteLookupItem 'lkpTestTable', 13
**************************************************************************/
CREATE PROCEDURE [dbo].[usp_DeleteLookupItem]
(
	@LookupName VARCHAR(100),
	@LookupID INT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @SQL VARCHAR(500)
	
	SET @SQL = 'DELETE FROM ' + @LookupName + ' WHERE LookupID = ' + CONVERT(VARCHAR, @LookupID)

	EXEC (@SQL)
END







GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteOutsideDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteOutsideDeveloper]
	@OutsideDeveloperID INT
AS
BEGIN
		DELETE FROM OutsideDeveloper WHERE OutsideDeveloperID = @OutsideDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeletePortalSite]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DeletePortalSite]
	@PortalSiteID INT
AS
BEGIN
		DELETE FROM PortalSites WHERE PortalSiteID = @PortalSiteID
END






GO
/****** Object:  StoredProcedure [dbo].[usp_DeletePortalSiteADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[usp_DeletePortalSiteADGroup]
(
	@PortalSiteID INT,
	@ADGroupID INT
)
AS
BEGIN

	DELETE FROM PortalADGroup WHERE PortalSiteID = @PortalSiteID
	AND ADGroupID = @ADGroupID

END





GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteServer]
	@ServerID INT
AS
BEGIN
		DELETE FROM Server WHERE ServerID = @ServerID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_DesktopSelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_DesktopSelectByCriteria]
(
	@DesktopName VARCHAR(150) = '%'	
)
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		DesktopID,
		Name,
		Description,
		URL
	FROM Desktop
	WHERE IsNull(Name, '') LIKE '%' + @DesktopName + '%'
	ORDER BY Name

END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetADGroupsForApplication]
(
	@ApplicationID INT
)
AS
BEGIN

	SELECT adg.GroupName, adg.GroupPath, adg.ADGroupID  FROM ADGroup adg
	JOIN ApplicationADGroup aag
	ON aag.ApplicationID = @ApplicationID
	WHERE aag.ADGroupID = adg.ADGroupID
	ORDER BY adg.GroupName
	
END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForApplicationWithEmpNo]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetADGroupsForApplicationWithEmpNo]
(
	@ApplicationID INT,
	@EmpNo INT
)
AS
BEGIN

SELECT distinct adg.GroupName, adg.GroupPath, adg.ADGroupID FROM ADGroup adg
	LEFT JOIN ApplicationADGroup aag
	ON adg.ADGroupID = aag.ADGroupID
	LEFT JOIN Application app
	ON aag.ApplicationID = app.ApplicationID
	LEFT JOIN ApplicationContact ac
	ON app.ApplicationID = ac.ApplicationID
	LEFT JOIN Contact c
	ON ac.ContactID = c.ContactID	
	WHERE aag.ADGroupID = adg.ADGroupID
	AND aag.ApplicationID = @ApplicationID
	AND c.EmployeeNo = @EmpNo
	--AND c.ContactTypeID = 3
	AND adg.GroupName NOT IN(SELECT GroupName FROM ADGroupExclude)
	ORDER BY adg.GroupName
	
END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForCommunity]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_GetADGroupsForCommunity]
(
	@CommunityID INT
	
)
AS
BEGIN

	SELECT * FROM ADGroup adg
	JOIN CommunityADGroup cag
	ON cag.CommunityID = @CommunityID
	WHERE cag.ADGroupID = adg.ADGroupID	
	ORDER BY adg.GroupName
	
END







GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForDesktop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetADGroupsForDesktop]
(
	@DesktopID INT
	
)
AS
BEGIN

	SELECT * FROM ADGroup adg
	JOIN DesktopADGroup dag
	ON dag.DesktopID = @DesktopID
	WHERE dag.ADGroupID = adg.ADGroupID	
	AND adg.GroupName NOT IN(SELECT GroupName FROM ADGroupExclude)
	ORDER BY adg.GroupName
	
END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForPortalSite]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetADGroupsForPortalSite]
(
	@PortalSiteID INT
	
)
AS
BEGIN

	SELECT * FROM ADGroup adg
	JOIN PortalADGroup pag
	ON pag.PortalSiteID = @PortalSiteID
	WHERE pag.ADGroupID = adg.ADGroupID	
	AND adg.GroupName NOT IN(SELECT GroupName FROM ADGroupExclude)
	ORDER BY adg.GroupName
	
END






GO
/****** Object:  StoredProcedure [dbo].[usp_GetADGroupsForWorkspace]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[usp_GetADGroupsForWorkspace]
(
	@CommunityID INT
)
AS
BEGIN

	SELECT * FROM ADGroup adg
	JOIN CommunityADGroup cag
	ON cag.CommunityID = @CommunityID
	WHERE cag.ADGroupID = adg.ADGroupID
	AND adg.GroupName NOT IN(SELECT GroupName FROM ADGroupExclude)
	ORDER BY adg.GroupName
	
END







GO
/****** Object:  StoredProcedure [dbo].[usp_GetApplicationDatabases]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_GetApplicationDatabases]
(
	@ApplicationID INT,
	@Include BIT
)
AS
BEGIN
	
	IF (@Include = 1)
	BEGIN
		SELECT 
			DatabaseID,
			Name as DatabaseName,
			lkpDatabaseType.Description as DatabaseType,
			case when IsDevDB = 1 then 'Dev' when IsTestDB = 1 then 'Test' when IsProdDB = 1 then 'Prod' else 'Error' end as 'DatabaseEnviron'			
		FROM Databases		
		LEFT JOIN lkpDatabaseType (NOLOCK) ON DBTypeID = lkpDatabaseType.LookupID
		WHERE DatabaseID IN (Select databaseid ID FROM ApplicationDatabase where ApplicationID = @ApplicationID)
		
		ORDER BY Name 
	END
	ELSE
	BEGIN
		SELECT 
			DatabaseID,
			Name as DatabaseName,
			lkpDatabaseType.Description as DatabaseType,
			case when IsDevDB = 1 then 'Dev' when IsTestDB = 1 then 'Test' when IsProdDB = 1 then 'Prod' else 'Error' end as 'DatabaseEnviron'			
		FROM Databases		
		LEFT JOIN lkpDatabaseType (NOLOCK) ON DBTypeID = lkpDatabaseType.LookupID
		WHERE DatabaseID NOT IN (Select databaseid ID FROM ApplicationDatabase where ApplicationID = @ApplicationID)
		
		ORDER BY Name 
	END
		
END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetApplicationServers]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetApplicationServers]
(
	@ApplicationID INT,
	@Include BIT
)
AS
BEGIN

IF @Include = 1
BEGIN
	SELECT
		s.ServerID,
		ServerTypeID as Type,
		IsNull(lkpServerType.Description, '') as ServerType,
		IsNull(lkpServerUse.Description, '') as ServerUse,
		[Name],
		IsNull(lkpLocation.Description, '') as Location,
		IPAddress,
		lkpAdminEngineer.Description as AdminEngineer,
		lkpITGroup.Description as ITGroup,
		Comment
		FROM Server s
		LEFT JOIN lkpAdminEngineer (NOLOCK) ON AdminEngineerID = lkpAdminEngineer.LookupID
		LEFT JOIN lkpServerType (NOLOCK) ON ServerTypeID = lkpServerType.LookupID
		LEFT JOIN lkpServerUse (NOLOCK) ON ServerUseID = lkpServerUse.LookupID
		LEFT JOIN lkpLocation (NOLOCK) ON LocationID = lkpLocation.LookupID
		LEFT JOIN lkpITGroup (NOLOCK) ON ITGroupID = lkpITGroup.LookupID
	WHERE 
		ServerID IN (SELECT ServerID FROM Installation WHERE ApplicationID = @ApplicationID)
	ORDER BY [Name]	
END
ELSE
BEGIN
	SELECT
		s.ServerID,
		ServerTypeID as Type,
		IsNull(lkpServerType.Description, '') as ServerType,
		IsNull(lkpServerUse.Description, '') as ServerUse,
		[Name],
		IsNull(lkpLocation.Description, '') as Location,
		IPAddress,
		lkpAdminEngineer.Description as AdminEngineer,
		lkpITGroup.Description as ITGroup,
		Comment
		FROM Server s
		LEFT JOIN lkpAdminEngineer (NOLOCK) ON AdminEngineerID = lkpAdminEngineer.LookupID
		LEFT JOIN lkpServerType (NOLOCK) ON ServerTypeID = lkpServerType.LookupID
		LEFT JOIN lkpServerUse (NOLOCK) ON ServerUseID = lkpServerUse.LookupID
		LEFT JOIN lkpLocation (NOLOCK) ON LocationID = lkpLocation.LookupID
		LEFT JOIN lkpITGroup (NOLOCK) ON ITGroupID = lkpITGroup.LookupID
	WHERE 
		ServerID NOT IN (SELECT ServerID FROM Installation WHERE ApplicationID = @ApplicationID)
	ORDER BY [Name]	
END

END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetApplicationsForServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_GetApplicationsForServer]
(
	@ServerID INT
)
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		ApplicationID,
		Name,
		--CompanyName,
		case developertypeid when 1 then CompanyName else 'GGP' end as 'CompanyName',
		IsNull(lkpAppType.Description, '')  as ApplicationType,
		ShortDescription,
		LongDescription
	FROM Application
	LEFT JOIN lkpAppType (NOLOCK) ON ApplicationTypeID = lkpAppType.LookupID
	LEFT JOIN OutsideDeveloper od (NOLOCK) ON DeveloperID = od.OutsideDeveloperID
	WHERE 
		ApplicationID IN (SELECT ApplicationID FROM Installation WHERE ServerID = @ServerID)
	ORDER BY Name

END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetCodeTableList]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/**************************************************************************
    PROCEDURE:      usp_GetCodeTableList
    AUTHOR:         Laimonas Simutis brought from PropertyTax
    CREATE DATE:    07/26/2006	
    PURPOSE:        Return a list of code tables for selection in the code table admin screen.
    INPUT:          
    OUTPUT:         
    HISTORY:        
    TEST:           usp_GetCodeTableList
**************************************************************************/
CREATE PROCEDURE [dbo].[usp_GetCodeTableList]
AS
BEGIN
	SET NOCOUNT ON
	SELECT
		substring(TABLE_NAME,4,len(TABLE_NAME)-3)
	FROM information_schema.columns WHERE table_catalog = 'GGPApplications' AND table_name LIKE 'lkp%' AND column_name = 'LookupID'
	ORDER BY TABLE_NAME
	
END







GO
/****** Object:  StoredProcedure [dbo].[usp_GetCommunitiesForGroups]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetCommunitiesForGroups]
(
	@GroupXML TEXT
)
AS
BEGIN

	DECLARE @groups TABLE
	(
		GroupName VARCHAR(255)
	)

	DECLARE	@hDoc INT

	EXEC sp_xml_preparedocument @hDoc OUTPUT, @GroupXML

	INSERT INTO @groups (GroupName)
	SELECT xdoc.[name] FROM OPENXML(@hdoc, '//groups/group', 1)
	WITH ([name] varchar(255)) xdoc

	EXEC sp_xml_removedocument @hDoc

	SELECT DISTINCT c.* from Community c
	join CommunityADGroup cadg
	ON cadg.CommunityID = c.CommunityID
	JOIN ADGroup ad
	ON ad.ADGroupID = cadg.ADGroupID
	WHERE ad.GroupName in
	(SELECT GroupName FROM @groups) AND isVisibleInsideGGP = 1
	ORDER BY c.Name

END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetContactType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetContactType] 
	@EmpNo INT,
	@ApplicationID INT
AS


BEGIN

	

SELECT DISTINCT(app.Name), c.ContactTypeID FROM ADGroup adg
	LEFT JOIN ApplicationADGroup aag
	ON adg.ADGroupID = aag.ADGroupID
	LEFT JOIN Application app
	ON aag.ApplicationID = app.ApplicationID
	LEFT JOIN ApplicationContact ac
	ON app.ApplicationID = ac.ApplicationID
	LEFT JOIN Contact c
	ON ac.ContactID = c.ContactID	
	WHERE aag.ADGroupID = adg.ADGroupID
	AND aag.ApplicationID = @ApplicationID
	AND c.EmployeeNo = @EmpNo	
	ORDER BY c.ContactTypeID DESC
	
END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetDatabaseServers]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetDatabaseServers]
(
	@DatabaseID INT,
	@Include BIT
)
AS
BEGIN

IF @Include = 1
BEGIN
	SELECT
		s.ServerID,
		ServerTypeID as Type,
		IsNull(lkpServerType.Description, '') as ServerType,
		IsNull(lkpServerUse.Description, '') as ServerUse,
		[Name],
		IsNull(lkpLocation.Description, '') as Location,
		IPAddress,
		lkpAdminEngineer.Description as AdminEngineer,
		lkpITGroup.Description as ITGroup,
		Comment
		FROM Server s
		LEFT JOIN lkpAdminEngineer (NOLOCK) ON AdminEngineerID = lkpAdminEngineer.LookupID
		LEFT JOIN lkpServerType (NOLOCK) ON ServerTypeID = lkpServerType.LookupID
		LEFT JOIN lkpServerUse (NOLOCK) ON ServerUseID = lkpServerUse.LookupID
		LEFT JOIN lkpLocation (NOLOCK) ON LocationID = lkpLocation.LookupID
		LEFT JOIN lkpITGroup (NOLOCK) ON ITGroupID = lkpITGroup.LookupID
	WHERE 
		ServerID IN (SELECT ServerID FROM ServerDatabase WHERE DatabaseID = @DatabaseID)
	ORDER BY [Name]	
END
ELSE
BEGIN
	SELECT
		s.ServerID,
		ServerTypeID as Type,
		IsNull(lkpServerType.Description, '') as ServerType,
		IsNull(lkpServerUse.Description, '') as ServerUse,
		[Name],
		IsNull(lkpLocation.Description, '') as Location,
		IPAddress,
		lkpAdminEngineer.Description as AdminEngineer,
		lkpITGroup.Description as ITGroup,
		Comment
		FROM Server s
		LEFT JOIN lkpAdminEngineer (NOLOCK) ON AdminEngineerID = lkpAdminEngineer.LookupID
		LEFT JOIN lkpServerType (NOLOCK) ON ServerTypeID = lkpServerType.LookupID
		LEFT JOIN lkpServerUse (NOLOCK) ON ServerUseID = lkpServerUse.LookupID
		LEFT JOIN lkpLocation (NOLOCK) ON LocationID = lkpLocation.LookupID
		LEFT JOIN lkpITGroup (NOLOCK) ON ITGroupID = lkpITGroup.LookupID
	WHERE 
		ServerID NOT IN (SELECT ServerID FROM ServerDatabase WHERE DatabaseID = @DatabaseID)
	ORDER BY [Name]	
END

END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetDesktopsByOwner]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_GetDesktopsByOwner]
(
	@DesktopAdminID INT
)
AS
BEGIN
	SELECT Name,DesktopID FROM Desktop
	WHERE DesktopAdminID = @DesktopAdminID
END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetDesktopsForGroups]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetDesktopsForGroups]
(
	@GroupXML TEXT
)
AS
BEGIN

	DECLARE @groups TABLE
	(
		GroupName VARCHAR(255)
	)

	DECLARE	@hDoc INT

	EXEC sp_xml_preparedocument @hDoc OUTPUT, @GroupXML

	INSERT INTO @groups (GroupName)
	SELECT xdoc.[name] FROM OPENXML(@hdoc, '//groups/group', 1)
	WITH ([name] varchar(255)) xdoc

	EXEC sp_xml_removedocument @hDoc

	SELECT DISTINCT d.* from Desktop d
	join DesktopADGroup dadg
	ON dadg.DesktopID = d.DesktopID
	JOIN ADGroup ad
	ON ad.ADGroupID = dadg.ADGroupID
	WHERE ad.GroupName in
	(SELECT GroupName FROM @groups)
	ORDER BY d.Name

END




GO
/****** Object:  StoredProcedure [dbo].[usp_GetLookupList]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/**************************************************************************
    PROCEDURE:      dbo.usp_GetLookupList
    AUTHOR:         Laimonas Simutis brought from Property Tax
    CREATE DATE:    07/26/2006
    PURPOSE:        Return all rows from a lookup table.
    INPUT:          
    OUTPUT:         
    HISTORY:        
    TEST:           usp_GetLookupList 'cLeaseType'
**************************************************************************/
CREATE PROCEDURE [dbo].[usp_GetLookupList]
(
	@LookupName VARCHAR(100)
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @SQL VARCHAR(500)
	
	SET @SQL = 'SELECT LookupID, CodeValue, Description, EffectiveDate, InvalidDate, CodeValue + Space(1) + Description FROM ' + @LookupName + ' ORDER BY Description'

	EXEC (@SQL)
END







GO
/****** Object:  StoredProcedure [dbo].[usp_GetPortalSitesByOwner]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetPortalSitesByOwner]
(
	@PortalAdminID INT
)
AS
BEGIN
	SELECT Name,PortalSiteID FROM PortalSites
	WHERE PortalAdminID = @PortalAdminID
END






GO
/****** Object:  StoredProcedure [dbo].[usp_GetPortalSitesForGroups]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  proc [dbo].[usp_GetPortalSitesForGroups]
(
	@GroupXML TEXT
)
AS
BEGIN

	DECLARE @groups TABLE
	(
		GroupName VARCHAR(255)
	)

	DECLARE	@hDoc INT

	EXEC sp_xml_preparedocument @hDoc OUTPUT, @GroupXML -- '<groups><group name="SPS-W-PMO Team-ER" /><group name="ReportingGroup {f6286bf3-6a54-44e3-8d64-5290db7b0219}" /><group name="UserGroup {f6286bf3-6a54-44e3-8d64-5290db7b0219}" /><group name="SPS-W-IS Roadmap-EC" /><group name="TEK_ExampleApp_Browser" /><group name="EXCH-Archive Users" /><group name="CTX-Leasemaker Desktop Test" /><group name="SHR-WEB00-NETAPPS" /><group name="SPS-W-IS Development-EC" /><group name="BDL{GGP-VMD}{38f9bed9-0177-45de-a30c-9063e36c2499}" /><group name="app_fm_architects" /><group name="app_fm_users" /><group name="SPS-P-GGP Lingo-EM" /><group name="InsideGGP-TestUsers" /><group name="SPS-P-News-EM" /><group name="SPS-P-Key Contacts-EC" /><group name="REIT-Admin" /><group name="Chicago IS Application Services" /><group name="Application Development Access Group" /><group name="SPS-W-Environmental Engineering Services-EM" /><group name="CAR-Admin" /><group name="GGPAPPS_Contrib" /><group name="APP-CTXFS-Data-TEK" /><group name="Softricity Users" /><group name="Chgo Portfolio Review Contacts Editor Access" /><group name="Chicago MIS Local Admins" /><group name="STS_MIS_IT_Browser" /><group name="appsupport" /><group name="STS_Admin" /><group name="MOM Operator Console Users" /><group name="EMPLOYEES" /><group name="SPS-W-20th Century Fox-EC" /><group name="GGP Employees" /><group name="CTX-Licensemaker Users" /><group name="Makers" /><group name="DYNA Accountants" /><group name="Team-Fin Teams-Dyna" /><group name="CTX-JDE Users" /><group name="Team-Citrix-Financial-JDEdwards Users" /><group name="JDEdwards Users" /><group name="O-MIS" /><group name="GGP Power Users" /><group name="CTX-Messenger" /><group name="WF-IS Access" /><group name="Leasemaker_Authors" /><group name="SPS_Sharepoint_Web_Admins" /><group name="It Development Editor Access" /><group name="W-IT-Development" /><group name="CTX-Heat Users" /><group name="Blackberry Users" /><group name="SPS-W-Information Technology-EC" /><group name="Leasemaker_Coordinators" /><group name="Chicago Legal Local Admins" /><group name="CTX-Leasemaker Users" /><group name="CTX-Leasemaker Helpdesk" /><group name="D-InfoTech" /><group name="Tm-MIS-SO Documentation Viewers" /></groups>'

	INSERT INTO @groups (GroupName)
	SELECT xdoc.[name] FROM OPENXML(@hdoc, '//groups/group', 1)
	WITH ([name] varchar(255)) xdoc

	EXEC sp_xml_removedocument @hDoc

	SELECT DISTINCT p.* from PortalSites p
	join PortalADGroup padg
	ON padg.PortalSiteID = p.PortalSiteID
	JOIN ADGroup ad
	ON ad.ADGroupID = padg.ADGroupID
	WHERE ad.GroupName in
	(SELECT GroupName FROM @groups)
	ORDER BY p.Name

END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetServerDatabases]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetServerDatabases]
(
	@ServerID INT
)
as
begin
	SELECT 
		DatabaseID,
		Name as DatabaseName,
		lkpDatabaseType.Description as DatabaseType,
		case when IsDevDB = 1 then 'Dev' when IsTestDB = 1 then 'Test' when IsProdDB = 1 then 'Prod' else 'Error' end as 'DatabaseEnviron'		
	FROM Databases
	LEFT JOIN lkpDatabaseType (NOLOCK) ON DBTypeID = lkpDatabaseType.LookupID
	WHERE DatabaseID IN (Select databaseid ID FROM serverdatabase where serverid = @Serverid)
	
	ORDER BY Name 
		
end





GO
/****** Object:  StoredProcedure [dbo].[usp_GetServersForHost]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_GetServersForHost]
(
	@HostID INT
)
AS
BEGIN
	SELECT 
		s.Name as 'Name',
		ae.Description as 'Admin Engineer',
		s.IPAddress as 'IP Address',
		st.Description as 'Server Type',
		su.Description as 'Server Use',
		ig.Description as 'Group'
	FROM Server s
		LEFT JOIN lkpAdminEngineer ae on s.AdminEngineerID = ae.LookupID
		LEFT JOIN lkpServerType st on s.ServerTypeID = st.LookupID
		LEFT JOIN lkpServerUse su on s.ServerUseID = su.LookupID
		LEFT JOIN lkpITGroup ig on s.ITGroupID = ig.LookupID
	WHERE VHostName in
	(SELECT Name FROM Server WHERE ServerID = @HostID)
END





GO
/****** Object:  StoredProcedure [dbo].[usp_GetVirtualHosts]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[usp_GetVirtualHosts]
as
begin
	select Name from server WHERE VirtualHostType = 0
	order by name
end





GO
/****** Object:  StoredProcedure [dbo].[usp_GetWorkSpacesByOwner]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_GetWorkSpacesByOwner]
(
	@CommunityAdminID INT
)
AS
BEGIN
	SELECT Name,CommunityID FROM Community
	WHERE CommunityAdminID = @CommunityAdminID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[usp_InsertADGroup]
	@GroupName VARCHAR(255),
	@GroupPath VARCHAR(255),
	@ADGroupID INT
AS
BEGIN

	IF NOT EXISTS(SELECT * FROM ADGroup WHERE GroupName = @GroupName)
	BEGIN
		INSERT INTO ADGroup (
			GroupName,
			GroupPath)
		VALUES (
			@GroupName,
			@GroupPath)
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT ADGroupID FROM ADGroup WHERE GroupName = @GroupName
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertApplicationADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertApplicationADGroup]
	@ApplicationADGroupID INT,
	@ApplicationID INT,
	@ADGroupID INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM ApplicationADGroup WHERE ApplicationID = @ApplicationID AND ADGroupID = @ADGroupID)
	BEGIN
		INSERT INTO ApplicationADGroup (
			ApplicationID,
			ADGroupID)
		VALUES (
			@ApplicationID,
			@ADGroupID)
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT ApplicationADGroupID FROM ApplicationADGroup 
		WHERE ApplicationID = @ApplicationID AND ADGroupID = @ADGroupID
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertApplicationContact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[usp_InsertApplicationContact]
(
	@ApplicationID INT,
	@ContactID INT
)
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM ApplicationContact WHERE ApplicationID = @ApplicationID AND ContactID = @ContactID)
	BEGIN
		INSERT INTO ApplicationContact (ApplicationID, ContactID)
		VALUES (@ApplicationID, @ContactID)
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertComment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertComment]
	@ParentID INT,
	@Comment TEXT,
	@CommentID INT,
	@DateEntered DATETIME,
	@ParentType VARCHAR(10),
	@EnteredBy VARCHAR(100)
AS
BEGIN
	INSERT INTO Comment (
		ParentID,
		Comment,
		DateEntered,
		ParentType,
		EnteredBy)
	VALUES (
		@ParentID,
		@Comment,
		@DateEntered,
		@ParentType,
		@EnteredBy)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertCommunity]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertCommunity]
	@CommunityTypeID INT,
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreatedDate DATETIME,
	@Name VARCHAR(50),
	@CommunityID INT,
	@CommunityAdminID VARCHAR(50),
	@IsVisibleInsideGGP BIT
AS
BEGIN
	INSERT INTO Community (
		CommunityTypeID,
		LastUpdated,
		LastUpdatedBy,
		Description,
		URL,
		CreatedDate,
		Name,
		CommunityAdminID,
		IsVisibleInsideGGP)
	VALUES (
		@CommunityTypeID,
		@LastUpdated,
		@LastUpdatedBy,
		@Description,
		@URL,
		@CreatedDate,
		@Name,
		@CommunityAdminID,
		@IsVisibleInsideGGP)
	SELECT @@IDENTITY
END






GO
/****** Object:  StoredProcedure [dbo].[usp_InsertCommunityADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[usp_InsertCommunityADGroup]
	@CommunityADGroupID INT,
	@CommunityID INT,
	@ADGroupID INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM CommunityADGroup WHERE CommunityID = @CommunityID AND ADGroupID = @ADGroupID)
	BEGIN
		INSERT INTO CommunityADGroup (
			CommunityID,
			ADGroupID)
		VALUES (
			@CommunityID,
			@ADGroupID)
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT CommunityADID FROM CommunityADGroup 
		WHERE CommunityID = @CommunityID AND ADGroupID = @ADGroupID
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertContact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertContact]
	@LastName VARCHAR(50),
	@ContactTypeID INT,
	@FirstName VARCHAR(50),
	@MiddleInitial VARCHAR(1),
	@EmployeeNo VARCHAR(50),
	@SID VARCHAR(50),
	@IsValid BIT,
	@Email VARCHAR(50),
	@Phone VARCHAR(100),
	@ContactID INT,
	@Title VARCHAR(100),
	@LoginName VARCHAR(50)
AS
BEGIN
	INSERT INTO Contact (
		LastName,
		ContactTypeID,
		FirstName,
		MiddleInitial,
		EmployeeNo,
		SID,
		IsValid,
		Email,
		Phone,
		Title,
		LoginName)
	VALUES (
		@LastName,
		@ContactTypeID,
		@FirstName,
		@MiddleInitial,
		@EmployeeNo,
		@SID,
		@IsValid,
		@Email,
		@Phone,
		@Title,
		@LoginName)
	SELECT @@IDENTITY
END




GO
/****** Object:  StoredProcedure [dbo].[usp_InsertDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertDatabase]
	@LastUpdatedBy VARCHAR(100),
	@ServicePack VARCHAR(50),
	@InstalledDate DATETIME,
	@IsTestDB BIT,
	@IsDevDB BIT,
	@DBTypeID INT,
	@LastUpdated DATETIME,
	@Name VARCHAR(100),
	@Comments VARCHAR(1000),
	@DatabaseID INT,
	@IsProdDB BIT,
	@DBVersion VARCHAR(50)
AS
BEGIN
	INSERT INTO Databases (
		LastUpdatedBy,
		ServicePack,
		InstalledDate,
		IsTestDB,
		IsDevDB,
		DBTypeID,
		LastUpdated,
		Name,
		Comments,
		IsProdDB,
		DBVersion)	
	VALUES (
		@LastUpdatedBy,
		@ServicePack,
		@InstalledDate,
		@IsTestDB,
		@IsDevDB,
		@DBTypeID,
		@LastUpdated,
		@Name,
		@Comments,
		@IsProdDB,
		@DBVersion)		
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertDesktop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertDesktop]
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreatedDate DATETIME,
	@Name VARCHAR(50),
	@DesktopID INT,
	@DesktopAdminID VARCHAR(50)
AS
BEGIN
	INSERT INTO Desktop (
		LastUpdated,
		LastUpdatedBy,
		Description,
		URL,
		CreateDate,
		Name,
		DesktopAdminID)
	VALUES (
		@LastUpdated,
		@LastUpdatedBy,
		@Description,
		@URL,
		@CreatedDate,
		@Name,
		@DesktopAdminID)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertDesktopADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertDesktopADGroup]
	@DesktopADGroupID INT,
	@DesktopID INT,
	@ADGroupID INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM DesktopADGroup WHERE DesktopID = @DesktopID AND ADGroupID = @ADGroupID)
	BEGIN
		INSERT INTO DesktopADGroup (
			DesktopID,
			ADGroupID)
		VALUES (
			@DesktopID,
			@ADGroupID)
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT DesktopADID FROM DesktopADGroup 
		WHERE DesktopID = @DesktopID AND ADGroupID = @ADGroupID
	END
END




GO
/****** Object:  StoredProcedure [dbo].[usp_InsertDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertDocument]
	@Name VARCHAR(255),
	@Path VARCHAR(500),
	@DocumentID INT
AS
BEGIN
	INSERT INTO Document (
		Name,
		Path)
	VALUES (
		@Name,
		@Path)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertGGPDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertGGPDeveloper]
	@LeadDeveloper VARCHAR(200),
	@GGPDeveloperID INT,
	@ProgrammingLanguageID INT,
	@BusinessAnalyst VARCHAR(200)
AS
BEGIN
	INSERT INTO GGPDeveloper (
		LeadDeveloper,
		ProgrammingLanguageID,
		BusinessAnalyst)
	VALUES (
		@LeadDeveloper,
		@ProgrammingLanguageID,
		@BusinessAnalyst)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertInstallation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertInstallation]
	@ServerID INT,
	@ApplicationID INT
AS
BEGIN
	INSERT INTO Installation (
		ServerID,
		ApplicationID)
	VALUES (
		@ServerID,
		@ApplicationID)
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertOutsideDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InsertOutsideDeveloper]
	@OutsideDeveloperID INT,
	@ContactID INT,
	@CompanyName VARCHAR(100)
AS
BEGIN
	INSERT INTO OutsideDeveloper (
		ContactID,
		CompanyName)
	VALUES (
		@ContactID,
		@CompanyName)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_InsertPortalSite]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertPortalSite]
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreateDate DATETIME,
	@Name VARCHAR(50),
	@PortalID INT,
	@PortalAdminID VARCHAR(50)
	
AS
BEGIN
	INSERT INTO PortalSites (
		LastUpdated,
		LastUpdatedBy,
		Description,
		URL,
		CreateDate,
		Name,
		PortalAdminID)		
	VALUES (
		
		@LastUpdated,
		@LastUpdatedBy,
		@Description,
		@URL,
		@CreateDate,
		@Name,
		@PortalAdminID
		)
	SELECT @@IDENTITY
END






GO
/****** Object:  StoredProcedure [dbo].[usp_InsertPortalSiteADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertPortalSiteADGroup]
	@PortalSiteADGroupID INT,
	@PortalSiteID INT,
	@ADGroupID INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM PortalADGroup WHERE PortalSiteID = @PortalSiteID AND ADGroupID = @ADGroupID)
	BEGIN
		INSERT INTO PortalADGroup (
			PortalSiteID,
			ADGroupID)
		VALUES (
			@PortalSiteID,
			@ADGroupID)
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT PortalADID FROM PortalADGroup 
		WHERE PortalSiteID = @PortalSiteID AND ADGroupID = @ADGroupID
	END
END






GO
/****** Object:  StoredProcedure [dbo].[usp_InsertServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_InsertServer]
	@IPAddress VARCHAR(40),
	@GroupDescription VARCHAR(500),
	@RebootSchedule VARCHAR(500),
	@AdminEngineerID INT,
	@NetworkTypeID INT,
	@ProcessorNumber INT,
	@IPAddress2 VARCHAR(40),
	@LastUpdated DATETIME,
	@WebServerTypeID INT,
	@VirtualHostType INT,
	@ControllerNumber INT,
	@ILODNSName VARCHAR(50),
	@ITGroupID INT,
	@DiskCapacity VARCHAR(50),
	@BackupPath VARCHAR(500),
	@ServerMemory VARCHAR(50),
	@LocationID INT,
	@ServerID INT,
	@AntiVirusTypeID INT,
	@ServerTypeID INT,
	@ServerUseID INT,
	@BackupDescription VARCHAR(500),
	@OS INT,
	@BladeNo VARCHAR(50),
	@Generation VARCHAR(50),
	@CabinetNo VARCHAR(50),
	@ILOLicense VARCHAR(100),
	@CPUSpeed VARCHAR(50),
	@VHostName VARCHAR(50),
	@ModelNo VARCHAR(50),
	@Name VARCHAR(50),
	@Comment TEXT,
	@LastUpdatedBy VARCHAR(100),
	@SerialNo VARCHAR(50),
	@ILOIPAddress VARCHAR(40),
	@ChasisNo VARCHAR(50),
	@IPAddress3 VARCHAR(40),
   	@IPAddress4 VARCHAR(40),
	@SAN VARCHAR(40),
    @SANSwitchName VARCHAR(40),
    @SANSwitchPort  VARCHAR(40),
    @FibreBackup  VARCHAR(40),
    @FibreSwitchName  VARCHAR(40),
    @FibreSwitchPort  VARCHAR(40),
	@ClusterType  VARCHAR(40),
	@ClusterName  VARCHAR(40),
	@ClusterIP1  VARCHAR(40),
    @ClusterIP2  VARCHAR(40),
    @ManufacturerNumber  VARCHAR(40),
    @Manufacturer  VARCHAR(40),
    @NIC1Bundle  VARCHAR(40),
    @NIC2Bundle  VARCHAR(40),
    @NIC3Bundle  VARCHAR(40),
    @NIC4Bundle  VARCHAR(40),
    @NIC1Cable  VARCHAR(40),
    @NIC2Cable  VARCHAR(40),
    @NIC3Cable  VARCHAR(40),
    @NIC4Cable  VARCHAR(40),
    @ClusterSAN  VARCHAR(40),
    @LUNNumber  VARCHAR(40),    
    @WarrantyExpiration  VARCHAR(40),
	@SMTP BIT,
    @NIC1Interface VARCHAR(600),
    @NIC2Interface VARCHAR(600),
    @NIC3Interface VARCHAR(600),
    @NIC4Interface VARCHAR(600),
    @NIC1Subnet VARCHAR(600),
    @NIC2Subnet VARCHAR(600),
    @NIC3Subnet VARCHAR(600),
    @NIC4Subnet VARCHAR(600),
    @NIC1SwitchPortNum VARCHAR(600),
    @NIC2SwitchPortNum VARCHAR(600),
    @NIC3SwitchPortNum VARCHAR(600),
    @NIC4SwitchPortNum VARCHAR(600),
    @NIC1VLAN INT,
    @NIC2VLAN INT,
    @NIC3VLAN INT,
    @NIC4VLAN INT,
    @NIC1SwitchName INT,
    @NIC2SwitchName INT,
    @NIC3SwitchName INT,
    @NIC4SwitchName INT,
    @CPUType VARCHAR(600),
    @DNSServer1 VARCHAR(600),
    @DNSServer2 VARCHAR(600),
    @PhysicalDiskSize VARCHAR(600),
    @PhysicalDisks INT,
    @RaidType INT,
    @Partition1DriveName VARCHAR(600),
    @Partition2DriveName VARCHAR(600),
    @Partition3DriveName VARCHAR(600),
    @Partition4DriveName VARCHAR(600),
    @Partition5DriveName VARCHAR(600),
    @Partition6DriveName VARCHAR(600),
    @Partition7DriveName VARCHAR(600),
    @Partition8DriveName VARCHAR(600),
    @Partition9DriveName VARCHAR(600),
    @Partition10DriveName VARCHAR(600),
    @VPartition1DriveName VARCHAR(600),
    @VPartition2DriveName VARCHAR(600),
    @VPartition3DriveName VARCHAR(600),
    @VPartition4DriveName VARCHAR(600),
    @VPartition5DriveName VARCHAR(600),
    @VPartition6DriveName VARCHAR(600),
    @VPartition7DriveName VARCHAR(600),
    @VPartition8DriveName VARCHAR(600),
    @VPartition9DriveName VARCHAR(600),
    @VPartition10DriveName VARCHAR(600),
    @Partition1Size VARCHAR(600),
    @Partition2Size VARCHAR(600),
    @Partition3Size VARCHAR(600),
    @Partition4Size VARCHAR(600),
    @Partition5Size VARCHAR(600),
    @Partition6Size VARCHAR(600),
    @Partition7Size VARCHAR(600),
    @Partition8Size VARCHAR(600),
    @Partition9Size VARCHAR(600),
    @Partition10Size VARCHAR(600),
    @VPartition1Size VARCHAR(600),
    @VPartition2Size VARCHAR(600),
    @VPartition3Size VARCHAR(600),
    @VPartition4Size VARCHAR(600),
    @VPartition5Size VARCHAR(600),
    @VPartition6Size VARCHAR(600),
    @VPartition7Size VARCHAR(600),
    @VPartition8Size VARCHAR(600),
    @VPartition9Size VARCHAR(600),
    @VPartition10Size VARCHAR(600),
    @Ownership INT,
    @NumPartitions INT,
    @VNumPartitions INT,
    @ILOPassword VARCHAR(600)
AS
BEGIN
	INSERT INTO Server (
		IPAddress,
		GroupDescription,
		RebootSchedule,
		AdminEngineerID,
		NetworkTypeID,
		ProcessorNumber,
		IPAddress2,
		LastUpdated,
		WebServerTypeID,
		VirtualHostType,
		ControllerNumber,
		ILODNSName,
		ITGroupID,
		DiskCapacity,
		BackupPath,
		ServerMemory,
		LocationID,
		AntiVirusTypeID,
		ServerTypeID,
		ServerUseID,
		BackupDescription,
		OS,
		BladeNo,
		Generation,
		CabinetNo,
		ILOLicense,
		CPUSpeed,
		VHostName,
		ModelNo,
		Name,
		Comment,
		LastUpdatedBy,
		SerialNo,
		ILOIPAddress,
		ChasisNo,
		IPAddress3,
		IPAddress4,
		SANSwitchName,
        SANSwitchPort,
        FibreBAckup,
        FibreSwitchName,
        FibreSwitchPort,
		ClusterType,
		ClusterName,
		ClusterIP1,
	    ClusterIP2 ,
	    ManufacturerNumber,
	    Manufacturer,
	    NIC1Bundle,
	    NIC2Bundle,
	    NIC3Bundle,
	    NIC4Bundle,
	    NIC1Cable,
	    NIC2Cable,
	    NIC3Cable,
	    NIC4CAble,
	    ClusterSAN,
	    LUNNumber, 
	    WarrantyExpiration,
		SMTP,
      NIC1Interface,
      NIC2Interface,
      NIC3Interface,
      NIC4Interface,
      NIC1Subnet,
      NIC2Subnet,
      NIC3Subnet,
      NIC4Subnet,
      NIC1SwitchPortNum,
      NIC2SwitchPortNum,
      NIC3SwitchPortNum,
      NIC4SwitchPortNum,
      NIC1VLAN,
      NIC2VLAN,
      NIC3VLAN,
      NIC4VLAN,
      NIC1SwitchName,
      NIC2SwitchName,
      NIC3SwitchName,
      NIC4SwitchName,
      CPUType,
      DNSServer1,
      DNSServer2,
      PhysicalDiskSize,
      PhysicalDisks,
      RaidType,
      Partition1DriveName,
      Partition2DriveName,
      Partition3DriveName,
      Partition4DriveName,
      Partition5DriveName,
      Partition6DriveName,
      Partition7DriveName,
      Partition8DriveName,
      Partition9DriveName,
      Partition10DriveName,
      VPartition1DriveName,
      VPartition2DriveName,
      VPartition3DriveName,
      VPartition4DriveName,
      VPartition5DriveName,
      VPartition6DriveName,
      VPartition7DriveName,
      VPartition8DriveName,
      VPartition9DriveName,
      VPartition10DriveName,
      Partition1Size,
      Partition2Size,
      Partition3Size,
      Partition4Size,
      Partition5Size,
      Partition6Size,
      Partition7Size,
      Partition8Size,
      Partition9Size,
      Partition10Size,
      VPartition1Size,
      VPartition2Size,
      VPartition3Size,
      VPartition4Size,
      VPartition5Size,
      VPartition6Size,
      VPartition7Size,
      VPartition8Size,
      VPartition9Size,
      VPartition10Size,
      Ownership,
      NumPartitions,
      VNumPartitions,
      ILOPassword
    )
	VALUES (
		@IPAddress,
		@GroupDescription,
		@RebootSchedule,
		@AdminEngineerID,
		@NetworkTypeID,
		@ProcessorNumber,
		@IPAddress2,
		@LastUpdated,
		@WebServerTypeID,
		@VirtualHostType,
		@ControllerNumber,
		@ILODNSName,
		@ITGroupID,
		@DiskCapacity,
		@BackupPath,
		@ServerMemory,
		@LocationID,
		@AntiVirusTypeID,
		@ServerTypeID,
		@ServerUseID,
		@BackupDescription,
		@OS,
		@BladeNo,
		@Generation,
		@CabinetNo,
		@ILOLicense,
		@CPUSpeed,
		@VHostName,
		@ModelNo,
		@Name,
		@Comment,
		@LastUpdatedBy,
		@SerialNo,
		@ILOIPAddress,
		@ChasisNo,
		@IPAddress3,
        @IPAddress4,
		@SANSwitchName,
	    @SANSwitchPort,
	   	@FibreBAckup,
	   	@FibreSwitchName,
	    @FibreSwitchPort,
		@ClusterType,
		@ClusterName,
		@ClusterIP1,
	    @ClusterIP2 ,
	    @ManufacturerNumber,
	    @Manufacturer,
	    @NIC1Bundle,
	    @NIC2Bundle,
	    @NIC3Bundle,
	    @NIC4Bundle,
	    @NIC1Cable,
	    @NIC2Cable,
	    @NIC3Cable,
	    @NIC4CAble,
	    @ClusterSAN,
	    @LUNNumber, 
	    @WarrantyExpiration,
		@SMTP,
        @NIC1Interface,
      @NIC2Interface,
      @NIC3Interface,
      @NIC4Interface,
      @NIC1Subnet,
      @NIC2Subnet,
      @NIC3Subnet,
      @NIC4Subnet,
      @NIC1SwitchPortNum,
      @NIC2SwitchPortNum,
      @NIC3SwitchPortNum,
      @NIC4SwitchPortNum,
      @NIC1VLAN,
      @NIC2VLAN,
      @NIC3VLAN,
      @NIC4VLAN,
      @NIC1SwitchName,
      @NIC2SwitchName,
      @NIC3SwitchName,
      @NIC4SwitchName,
      @CPUType,
      @DNSServer1,
      @DNSServer2,
      @PhysicalDiskSize,
      @PhysicalDisks,
      @RaidType,
      @Partition1DriveName,
      @Partition2DriveName,
      @Partition3DriveName,
      @Partition4DriveName,
      @Partition5DriveName,
      @Partition6DriveName,
      @Partition7DriveName,
      @Partition8DriveName,
      @Partition9DriveName,
      @Partition10DriveName,
      @VPartition1DriveName,
      @VPartition2DriveName,
      @VPartition3DriveName,
      @VPartition4DriveName,
      @VPartition5DriveName,
      @VPartition6DriveName,
      @VPartition7DriveName,
      @VPartition8DriveName,
      @VPartition9DriveName,
      @VPartition10DriveName,
      @Partition1Size,
      @Partition2Size,
      @Partition3Size,
      @Partition4Size,
      @Partition5Size,
      @Partition6Size,
      @Partition7Size,
      @Partition8Size,
      @Partition9Size,
      @Partition10Size,
      @VPartition1Size,
      @VPartition2Size,
      @VPartition3Size,
      @VPartition4Size,
      @VPartition5Size,
      @VPartition6Size,
      @VPartition7Size,
      @VPartition8Size,
      @VPartition9Size,
      @VPartition10Size,
      @Ownership,
      @NumPartitions,
      @VNumPartitions,
      @ILOPassword
)
	SELECT @@IDENTITY
END





GO
/****** Object:  StoredProcedure [dbo].[usp_Installation_Delete]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Installation_Delete
**		Desc: Delete a record in the Installations table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Installation_Delete]
(
@ServerID INTEGER,
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
DELETE FROM Installations
WHERE ServerID = @ServerID
AND ApplicationID = @ApplicationID







GO
/****** Object:  StoredProcedure [dbo].[usp_Installation_DeleteByServerID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************
	Name:		usp_Installation_DeleteByServerID
	Desc:		

	Author:		Alvin Ross
	Created Date:	9-15-2005
	
	History: 
 
	Who:			When:		What:
	------------------------------------------------------------------------------

*******************************************************************/
CREATE Procedure [dbo].[usp_Installation_DeleteByServerID]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON

DELETE FROM Installations
WHERE ServerID = @ServerID






GO
/****** Object:  StoredProcedure [dbo].[usp_Installation_Insert]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Installation_Insert
**		Desc: Insert a record into the Installations table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Installation_Insert]
(
@ServerID INTEGER,
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
INSERT INTO Installations
(
ServerID,
ApplicationID

)
VALUES 
(
@ServerID,
@ApplicationID
)







GO
/****** Object:  StoredProcedure [dbo].[usp_lkpCabNo]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_lkpCabNo] 
@CabNo VARCHAR(10)
AS
SELECT LookupID FROM lkpCabinet WHERE Description = @CabNo





GO
/****** Object:  StoredProcedure [dbo].[usp_lkpSPServerData]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_lkpSPServerData]

@Name VARCHAR(50)

 AS

SELECT Name FROM Server WHERE [Name] = @Name




GO
/****** Object:  StoredProcedure [dbo].[usp_LoadADGroupAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadADGroupAll]
AS
BEGIN
		SELECT * FROM ADGroup
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadADGroupByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadADGroupByID]
	@ADGroupID INT
AS
BEGIN
		SELECT * FROM ADGroup WHERE ADGroupID = @ADGroupID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadApplicationAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_LoadApplicationAll]
AS
BEGIN
		SELECT * FROM Application
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadApplicationByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_LoadApplicationByID]
	@ApplicationID INT
AS
BEGIN
		SELECT * FROM Application WHERE ApplicationID = @ApplicationID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadApplicationContacts]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[usp_LoadApplicationContacts]
(
	@ApplicationID INT
)
AS
BEGIN
	SELECT ContactID FROM ApplicationContact WHERE ApplicationID = @ApplicationID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadCommentByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_LoadCommentByID]
	@CommentID INT
AS
BEGIN
		SELECT * FROM Comment WHERE CommentID = @CommentID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadCommentByParent]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_LoadCommentByParent]
(
	@ParentID INT,	
	@ParentType VARCHAR(10)
)
AS
BEGIN
	SELECT * FROM Comment
	WHERE ParentID = @ParentID
	AND ParentType = @ParentType
	ORDER BY DateEntered DESC
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadCommunityAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadCommunityAll]
AS
BEGIN
		SELECT * FROM Community
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadCommunityByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadCommunityByID]
	@CommunityID INT
AS
BEGIN
		SELECT * FROM Community WHERE CommunityID = @CommunityID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadContactAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadContactAll]
AS
BEGIN
		SELECT * FROM Contact
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadContactByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadContactByID]
	@ContactID INT
AS
BEGIN
		SELECT * FROM Contact WHERE ContactID = @ContactID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDatabaseAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDatabaseAll]
AS
BEGIN
		SELECT * FROM Databases
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDatabaseByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDatabaseByID]
	@DatabaseID INT
AS
BEGIN
		SELECT * FROM Databases WHERE DatabaseID = @DatabaseID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDesktopAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDesktopAll]
AS
BEGIN
		SELECT * FROM Desktop
END




GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDesktopByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDesktopByID]
	@DesktopID INT
AS
BEGIN
		SELECT * FROM Desktop WHERE DesktopID = @DesktopID
END




GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDocumentAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDocumentAll]
AS
BEGIN
		SELECT * FROM Document
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDocumentByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadDocumentByID]
	@DocumentID INT
AS
BEGIN
		SELECT * FROM Document WHERE DocumentID = @DocumentID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadDocumentByParent]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_LoadDocumentByParent]
(
	@ParentID INT,
	@TypeID INT
)
AS
BEGIN
	IF @TypeID = 0
	BEGIN
		SELECT * FROM Document d
		JOIN ServerDocument sd ON d.DocumentID = sd.DocumentID
		WHERE sd.ServerID = @ParentID
	END
	ELSE IF @TypeID = 1
	BEGIN
		SELECT * FROM Document d
		JOIN ApplicationDocument sd ON d.DocumentID = sd.DocumentID
		WHERE sd.ApplicationID = @ParentID
	END
	ELSE IF @TypeID = 2
	BEGIN
		SELECT * FROM Document d
		JOIN DatabaseDocument sd ON d.DocumentID = sd.DocumentID
		WHERE sd.DatabaseID = @ParentID
	END
	ELSE IF @TypeID = 3
	BEGIN
		SELECT * FROM Document d
		JOIN CommunityDocument sd ON d.DocumentID = sd.DocumentID
		WHERE sd.CommunityID = @ParentID
	END
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadGGPDeveloperAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadGGPDeveloperAll]
AS
BEGIN
		SELECT * FROM GGPDeveloper
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadGGPDeveloperByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadGGPDeveloperByID]
	@GGPDeveloperID INT
AS
BEGIN
		SELECT * FROM GGPDeveloper WHERE GGPDeveloperID = @GGPDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadOutsideDeveloperAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadOutsideDeveloperAll]
AS
BEGIN
		SELECT * FROM OutsideDeveloper
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadOutsideDeveloperByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadOutsideDeveloperByID]
	@OutsideDeveloperID INT
AS
BEGIN
		SELECT * FROM OutsideDeveloper WHERE OutsideDeveloperID = @OutsideDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadPortalSiteAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadPortalSiteAll]
AS
BEGIN
		SELECT * FROM PortalSites
END






GO
/****** Object:  StoredProcedure [dbo].[usp_LoadPortalSiteByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadPortalSiteByID]
	@PortalSiteID INT
AS
BEGIN
		SELECT * FROM PortalSites WHERE PortalSiteID = @PortalSiteID
END






GO
/****** Object:  StoredProcedure [dbo].[usp_LoadServerAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LoadServerAll]
AS
BEGIN
		SELECT * FROM Server
END





GO
/****** Object:  StoredProcedure [dbo].[usp_LoadServerByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_LoadServerByID]
	@ServerID INT
AS
BEGIN
		SELECT * FROM Server WHERE ServerID = @ServerID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_Delete]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************************
**		File: 
**		Name: usp_MallServer_Delete
**		Desc: 
** 
**		Auth: Alvin Ross
**		Date: 10/05/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_Delete]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON

DELETE FROM MallServers
Where ServerID = @ServerID







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_DeleteDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/******************************************************************************
**		File: 
**		Name: usp_MallServer_DeleteDocument
**		Desc: 
**
**      Author: Alvin Ross
**      Date: 10/13/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_DeleteDocument]
(
@DocID INTEGER
)
AS
SET NOCOUNT ON
	
DELETE FROM MallServerDocuments
WHERE DocID = @DocID







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_Insert]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		File: 
**		Name: usp_MallServer_Insert
**		Desc: STORED PROCEDURE USED TO ADD ENTRIES TO THE MALL SERVERS TABLE
**
**
**		Auth: Alvin Ross
**		Date: 10/04/2005
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_MallServer_Insert]
(
@Name VARCHAR(150) = NULL,
@IPAddress VARCHAR(150) = NULL,
@MallNumber VARCHAR(150) = NULL,
@SiteTechnicalContact VARCHAR(150) = NULL,
@Portfolio VARCHAR(150) = Null,
@MailingAddress VARCHAR(150) = NULL,
@ContactBackup VARCHAR(150) = NULL,
@City VARCHAR(150) = NULL,
@PhysicalAddress VARCHAR(150) = NULL,
@Zip VARCHAR(150) = NULL,
@State VARCHAR(150) = NULL,
@Phone VARCHAR(150) = NULL,
@ServerName VARCHAR(150) = NULL,
@Gateway VARCHAR(150) = NULL,
@SubnetMask VARCHAR(150) = NULL,
@DHCPServer VARCHAR(150) = NULL,
@Model VARCHAR(150) = NULL,
@SerialNumber VARCHAR(150) = Null,
@WarrantyExp VARCHAR(150) = NULL,
@Status VARCHAR(150) = NULL,
@OperatingSystem VARCHAR(150) = NULL,
@DomainName VARCHAR(150) = NULL,
@SerialIP VARCHAR(150) = NULL,
@NetworkSiteCode VARCHAR(150) = NULL,
@DLCI VARCHAR(150) = NULL,
@EthernetIP VARCHAR(150) = NULL,
@LoopbackIP VARCHAR(150) = NULL,
@SprintCISID VARCHAR(150) = NULL,
@SprintDS0 VARCHAR(150) = NULL,
@RouterSerialNumber VARCHAR(150) = NULL,
@IOS VARCHAR(150) = NULL,
@CircuitID VARCHAR(150) = NULL,
@SprintDS1 VARCHAR(150) = Null,
@TelcoCKTID VARCHAR(150) = NULL,
@NetworkConn VARCHAR(150) = NULL,
@DMARCTermination VARCHAR(150) = NULL,
@MPLSBandwidth VARCHAR(150) = NULL,
@SprintAccount VARCHAR(150) = NULL,
@SprintMPLSPL VARCHAR(150) = NULL,
@SprintMPLSDS1 VARCHAR(150) = NULL,
@MPLSTelcoCircuitID VARCHAR(150) = NULL,
@MPLSOrder VARCHAR(150) = NULL,
@ModemRouter VARCHAR(150) = NULL,
@Vendor VARCHAR(150) = NULL,
@Consultant VARCHAR(150) = NULL,
@ConsultantEMail VARCHAR(150) = NULL,
@ConsultantPhone VARCHAR(150) = NULL,
@Timeslots datetime = NULL,
@MPLSOrderSubmitted datetime = NULL,
@MPLSCircuitInstallDate datetime = NULL,
@DateAcquired datetime = NULL,
@NewServerID INTEGER OUTPUT
)
AS

SET NOCOUNT ON
	
INSERT INTO MallServers
(
[Name],
IPAddress,
MallNumber,
SiteTechnicalContact,
Portfolio,
MailingAddress,
ContactBackup,
City,
PhysicalAddress,
Zip,
State,
Phone,
ServerName,
Gateway,
SubnetMask,
DHCPServer,
Model,
SerialNumber,
WarrantyExp,
Status,
OperatingSystem,
DomainName,
SerialIP,
NetworkSiteCode,
DLCI,
EthernetIP,
LoopbackIP,
SprintCISID,
SprintDS0,
RouterSerialNumber,
IOS,
CircuitID,
SprintDS1,
TelcoCKTID,
NetworkConn,
DMARCTermination,
MPLSBandwidth,
SprintAccount,
SprintMPLSPL,
SprintMPLSDS1,
MPLSTelcoCircuitID,
MPLSOrder,
ModemRouter,
Vendor,
Consultant,
ConsultantEMail,
ConsultantPhone,
Timeslots,
MPLSOrderSubmitted,
MPLSCircuitInstallDate,
DateAcquired
)
VALUES 
(
@Name,
@IPAddress,
@MallNumber,
@SiteTechnicalContact,
@Portfolio,
@MailingAddress,
@ContactBackup,
@City,
@PhysicalAddress,
@Zip,
@State,
@Phone,
@ServerName,
@Gateway,
@SubnetMask,
@DHCPServer,
@Model,
@SerialNumber,
@WarrantyExp,
@Status,
@OperatingSystem,
@DomainName,
@SerialIP,
@NetworkSiteCode,
@DLCI,
@EthernetIP,
@LoopbackIP,
@SprintCISID,
@SprintDS0,
@RouterSerialNumber,
@IOS,
@CircuitID,
@SprintDS1,
@TelcoCKTID,
@NetworkConn,
@DMARCTermination,
@MPLSBandwidth,
@SprintAccount,
@SprintMPLSPL,
@SprintMPLSDS1,
@MPLSTelcoCircuitID,
@MPLSOrder,
@ModemRouter,
@Vendor,
@Consultant,
@ConsultantEMail,
@ConsultantPhone,
@Timeslots,
@MPLSOrderSubmitted,
@MPLSCircuitInstallDate,
@DateAcquired
)

SELECT @NewServerID = @@IDENTITY







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_InsertDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		File: 
**		Name: usp_MallServer_InsertDocument
**		Desc: 
**
**		Auth: Alvin Ross
**		Date: 10/13/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_InsertDocument]
(
@ServerID INTEGER,
@DocName VARCHAR(200),
@DocPath VARCHAR(255)
)
AS

SET NOCOUNT ON

INSERT INTO MallServerDocuments
(
ServerID,
DocName,
DocPath
) 
VALUES 
(
@ServerID,
@DocName,
@DocPath
)







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_LookForDuplicateName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************************
**		File: 
**		Name: usp_MallServer_LookForDuplicateName
**		Desc: 
**
**		Auth: Alvin Ross
**		Date: 10/13/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_LookForDuplicateName]
(
@Name VARCHAR(150),
@ServerID INTEGER
)
AS

SET NOCOUNT ON

IF @ServerID > 0
	BEGIN	
		SELECT Count(*)
		FROM MallServers
		WHERE [Name] = @Name
		AND ServerID <> @ServerID
	END
ELSE
	BEGIN
		SELECT Count(*)
		FROM MallServers
		WHERE [Name] = @Name
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_SelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		File: 
**		Name: usp_MallServer_SelectByCriteria
**		Desc: 
**
**		Auth: Alvin Ross
**		Date: 10/13/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_SelectByCriteria]
(
@Name VARCHAR(150) = '%',
@Location VARCHAR(150) = '%',
@IPAddress VARCHAR(150) = '%',
@Type INTEGER = 99
)

AS

SET NOCOUNT ON

IF @Type = 99
	BEGIN
		SELECT
		ServerID,
		Type,
		dbo.udf_GetServerType(Type) AS ServerType,
		StartupInstructions,
		ShutdownInstructions,
		SoftwareSpecs,
		[Name],
		Location,
		IPAddress,
		IIS,
		InstallationSpecialInstructions,
		HardwareSpecs,
		DBMS,
		DBAAssigned,
		AdminEngineer,
		BackupSchedule
		FROM Servers
		WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)
		AND (Location LIKE '%' + @Location + '%' OR Location IS NULL)
		AND (IPAddress LIKE '%' + @IPAddress + '%'	OR IPAddress IS NULL)		
		ORDER BY [Name]
	END
ELSE
	BEGIN
		SELECT
		ServerID,
		Type,
		dbo.udf_GetServerType(Type) AS ServerType,
		StartupInstructions,
		ShutdownInstructions,
		SoftwareSpecs,
		[Name],
		Location,
		IPAddress,
		IIS,
		InstallationSpecialInstructions,
		HardwareSpecs,
		DBMS,
		DBAAssigned,
		AdminEngineer,
		BackupSchedule
		FROM Servers
		WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)
		AND (Location LIKE '%' + @Location + '%' OR Location IS NULL)
		AND (IPAddress LIKE '%' + @IPAddress + '%'	OR IPAddress IS NULL)		
		AND Type = @Type
		ORDER BY [Name]
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_SelectByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************************
**		File: 
**		Name: usp_MallServer_SelectByID
**		Desc: 
**
**		This template can be customized:
**              
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: 
**		Date: 
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_SelectByID]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule
FROM Servers
WHERE ServerID = @ServerID








GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_SelectByName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************************
**		File: 
**		Name: usp_MallServer_SelectByName
**		Desc: 
**
**		Auth: Alvin Ross
**		Date: 10/13/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_SelectByName]
(
@Name VARCHAR(150)
)
AS

SET NOCOUNT ON
	
SELECT
ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
[Name],
IPAddress,
MallNumber,
SiteTechnicalContact,
Portfolio,
MailingAddress,
ContactBackup,
City,
PhysicalAddress,
Zip,
State,
Phone,
ServerName,
Gateway,
SubnetMask,
DHCPServer,
Model,
SerialNumber,
WarrantyExp,
Status,
OperatingSystem,
DomainName,
SerialIP,
NetworkSiteCode,
DLCI,
EthernetIP,
LoopbackIP,
SprintCISID,
SprintDS0,
RouterSerialNumber,
IOS,
CircuitID,
SprintDS1,
TelcoCKTID,
NetworkConn,
DMARCTermination,
MPLSBandwidth,
SprintAccount,
SprintMPLSPL,
SprintMPLSDS1,
MPLSTelcoCircuitID,
MPLSOrder,
ModemRouter,
Vendor,
Consultant,
ConsultantEMail,
ConsultantPhone,
Timeslots,
MPLSOrderSubmitted,
MPLSCircuitInstallDate,
DateAcquired

FROM MallServers

WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)







GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_SelectDocuments]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		File: 
**		Name: usp_MallServer_SelectDocuments
**		Desc: 
**
**      Auth: Alvin
**		Date: 10/13/2005
**    
*******************************************************************************/

CREATE PROCEDURE [dbo].[usp_MallServer_SelectDocuments]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
DocID, 
DocName, 
DocPath 
FROM ServerDocuments
WHERE ServerID = @ServerID
ORDER BY DocName






GO
/****** Object:  StoredProcedure [dbo].[usp_MallServer_Update]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************************
**		File: 
**		Name: usp_MallServer_Update
**		Desc: 
**
**		Auth: Alvin Ross
**		Date: 10/05/2005
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_MallServer_Update]
(
@ServerID INTEGER,
@Name VARCHAR(150) = NULL,
@IPAddress VARCHAR(150) = NULL,
@MallNumber VARCHAR(150) = NULL,
@SiteTechnicalContact VARCHAR(150) = NULL,
@Portfolio VARCHAR(150) = Null,
@MailingAddress VARCHAR(150) = NULL,
@ContactBackup VARCHAR(150) = NULL,
@City VARCHAR(150) = NULL,
@PhysicalAddress VARCHAR(150) = NULL,
@Zip VARCHAR(150) = NULL,
@State VARCHAR(150) = NULL,
@Phone VARCHAR(150) = NULL,
@ServerName VARCHAR(150) = NULL,
@Gateway VARCHAR(150) = NULL,
@SubnetMask VARCHAR(150) = NULL,
@DHCPServer VARCHAR(150) = NULL,
@Model VARCHAR(150) = NULL,
@SerialNumber VARCHAR(150) = Null,
@WarrantyExp VARCHAR(150) = NULL,
@Status VARCHAR(150) = NULL,
@OperatingSystem VARCHAR(150) = NULL,
@DomainName VARCHAR(150) = NULL,
@SerialIP VARCHAR(150) = NULL,
@NetworkSiteCode VARCHAR(150) = NULL,
@DLCI VARCHAR(150) = NULL,
@EthernetIP VARCHAR(150) = NULL,
@LoopbackIP VARCHAR(150) = NULL,
@SprintCISID VARCHAR(150) = NULL,
@SprintDS0 VARCHAR(150) = NULL,
@RouterSerialNumber VARCHAR(150) = NULL,
@IOS VARCHAR(150) = NULL,
@CircuitID VARCHAR(150) = NULL,
@SprintDS1 VARCHAR(150) = Null,
@TelcoCKTID VARCHAR(150) = NULL,
@NetworkConn VARCHAR(150) = NULL,
@DMARCTermination VARCHAR(150) = NULL,
@MPLSBandwidth VARCHAR(150) = NULL,
@SprintAccount VARCHAR(150) = NULL,
@SprintMPLSPL VARCHAR(150) = NULL,
@SprintMPLSDS1 VARCHAR(150) = NULL,
@MPLSTelcoCircuitID VARCHAR(150) = NULL,
@MPLSOrder VARCHAR(150) = NULL,
@ModemRouter VARCHAR(150) = NULL,
@Vendor VARCHAR(150) = NULL,
@Consultant VARCHAR(150) = NULL,
@ConsultantEMail VARCHAR(150) = NULL,
@ConsultantPhone VARCHAR(150) = NULL,
@Timeslots datetime = NULL,
@MPLSOrderSubmitted datetime = NULL,
@MPLSCircuitInstallDate datetime = NULL,
@DateAcquired datetime = NULL
)
AS

SET NOCOUNT ON

UPDATE MallServers
SET 
[Name]=@Name,
IPAddress = @IPAddress,
MallNumber = @MallNumber,
SiteTechnicalContact = @SiteTechnicalContact,
Portfolio = @Portfolio,
MailingAddress = @MailingAddress,
ContactBackup = @ContactBackup,
City = @City,
PhysicalAddress = @PhysicalAddress,
Zip= @Zip,
State= @State,
Phone= @Phone,
ServerName= @ServerName,
Gateway= @Gateway,
SubnetMask= @SubnetMask,
DHCPServer= @DHCPServer,
Model= @Model,
SerialNumber= @SerialNumber,
WarrantyExp= @WarrantyExp,
Status= @Status,
OperatingSystem= @OperatingSystem,
DomainName= @DomainName,
SerialIP= @SerialIP,
NetworkSiteCode= @NetworkSiteCode,
DLCI= @DLCI,
EthernetIP= @EthernetIP,
LoopbackIP= @LoopbackIP,
SprintCISID= @SprintCISID,
SprintDS0= @SprintDS0,
RouterSerialNumber= @RouterSerialNumber,
IOS= @IOS,
CircuitID= @CircuitID,
SprintDS1= @SprintDS1,
TelcoCKTID= @TelcoCKTID,
NetworkConn= @NetworkConn,
DMARCTermination= @DMARCTermination,
MPLSBandwidth= @MPLSBandwidth,
SprintAccount= @SprintAccount,
SprintMPLSPL= @SprintMPLSPL,
SprintMPLSDS1= @SprintMPLSDS1,
MPLSTelcoCircuitID= @MPLSTelcoCircuitID,
MPLSOrder= @MPLSOrder,
ModemRouter= @ModemRouter,
Vendor= @Vendor,
Consultant= @Consultant,
ConsultantEMail= @ConsultantEMail,
ConsultantPhone= @ConsultantPhone,
Timeslots= @Timeslots,
MPLSOrderSubmitted= @MPLSOrderSubmitted,
MPLSCircuitInstallDate= @MPLSCircuitInstallDate,
DateAcquired= @DateAcquired
WHERE ServerID = @ServerID







GO
/****** Object:  StoredProcedure [dbo].[usp_PortalSiteADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[usp_PortalSiteADGroup]
(
	@PortalSiteID INT,
	@ADGroupID INT
)
AS
BEGIN

	DELETE FROM PortalADGroup WHERE PortalSiteID = @PortalSiteID
	AND ADGroupID = @ADGroupID

END





GO
/****** Object:  StoredProcedure [dbo].[usp_PortalSiteSelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_PortalSiteSelectByCriteria]
(
	@PortalSiteName VARCHAR(150) = '%'	
)
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		PortalSiteID,
		Name,
		Description,
		URL
	FROM PortalSites
	WHERE IsNull(Name, '') LIKE '%' + @PortalSiteName + '%'	
	ORDER BY Name

END






GO
/****** Object:  StoredProcedure [dbo].[usp_PutCodeTable]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/**************************************************************************
    PROCEDURE:      usp_PutCodeTable
    AUTHOR:         Laimonas Simutis taken from Property Tax Authors
    DATE:			7/25/2006
    PURPOSE:        Update code table values passing in the code table.
    INPUT:          
    OUTPUT:         
    HISTORY:        
    TEST:           usp_PutCodeTable 
**************************************************************************/
CREATE PROCEDURE [dbo].[usp_PutCodeTable]
(
		@TableName		VARCHAR(100),
		@LookupID		int,
		@LookupCode		VARCHAR(20),
		@LookupDesc		VARCHAR(200)
)
AS
BEGIN
	
	DECLARE @SQL VARCHAR(4000)
	if @LookupID = 0
	begin
		SET @SQL = 'INSERT INTO [' + @TableName + 
			'] (CodeValue, Description, EffectiveDate, InvalidDate)' +
			'VALUES (''' + @LookupCode + ''', ''' + @LookupDesc + ''', NULL, NULL)'
	END
	ELSE
	BEGIN
		SET @SQL = 'UPDATE ' + @TableName + 
				' SET CodeValue = ''' + @LookupCode + ''', ' +
				'Description = ''' + @LookupDesc + ''', ' + 
				'EffectiveDate = NULL, ' +
				'InvalidDate = NULL ' +
			' WHERE LookupID = ' + CONVERT(VARCHAR, @LookupID)
	END	
	
	EXEC (@SQL)
	END






GO
/****** Object:  StoredProcedure [dbo].[usp_RemoveApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_RemoveApplication]
(
	@ServerID INT,
	@ApplicationID INT
)
AS
BEGIN
	DELETE FROM Installation
	WHERE ServerID = @ServerID AND ApplicationID = @ApplicationID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_RemoveApplicationFromDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_RemoveApplicationFromDatabase]
(
	@DatabaseID INT,
	@ApplicationID INT
)
AS
BEGIN
	
	DELETE FROM ApplicationDatabase
	WHERE DatabaseID = @DatabaseID AND ApplicationID = @ApplicationID
	
END





GO
/****** Object:  StoredProcedure [dbo].[usp_RemoveServerDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_RemoveServerDatabase]
(
	@ServerID INT,
	@DatabaseID INT
)
AS
BEGIN
	DELETE FROM ServerDatabase
	WHERE ServerID = @ServerID AND DatabaseID = @DatabaseID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_Server_Delete]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_Delete
**		Desc: Delete a record in the Servers table and auxillary tables
**
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/22/2005
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_Delete]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON

DECLARE @ReturnCode INTEGER
SET @ReturnCode = 0

BEGIN TRAN

DELETE FROM ServerDocuments
WHERE ServerID = @ServerID
SELECT @ReturnCode = @@ERROR

IF @ReturnCode = 0
	BEGIN
		DELETE FROM Installations
		WHERE ServerID = @ServerID
		SELECT @ReturnCode = @@ERROR
	END
	
IF @ReturnCode = 0
	BEGIN
		DELETE FROM Servers
		WHERE ServerID = @ServerID
		SELECT @ReturnCode = @@ERROR
	END

IF @ReturnCode = 0
	BEGIN
		COMMIT TRAN
	END
ELSE
	BEGIN
		ROLLBACK TRAN
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_DeleteDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_DeleteDocument
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/15/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_DeleteDocument]
(
@DocID INTEGER
)
AS

SET NOCOUNT ON
	
DELETE FROM ServerDocuments
WHERE DocID = @DocID






GO
/****** Object:  StoredProcedure [dbo].[usp_Server_Insert]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_Insert
**		Desc: Insert a record into the Servers table
**
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/19/2005
**      Updated: 10/10/2005 - added the network entries to the list  Alvin Ross
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_Insert]
(
@Name VARCHAR(150) = NULL,
@ServerType INTEGER = NULL,
@Location VARCHAR(150) = NULL,
@IPAddress VARCHAR(150) = NULL,
@IIS VARCHAR(150) = BIT,
@DBMS VARCHAR(150) = NULL,
@DBAAssigned VARCHAR(150) = NULL,
@AdminEngineer VARCHAR(150) = NULL,
@StartupInstructions VARCHAR(150) = NULL,
@ShutdownInstructions VARCHAR(150) = NULL,
@SoftwareSpecs VARCHAR(150) = NULL,
@InstallationSpecialInstructions VARCHAR(150) = NULL,
@HardwareSpecs VARCHAR(150) = NULL,
@BackupSchedule VARCHAR(150) = NULL,
@NetworkGroup VARCHAR(150) = NULL,
@NetworkDescription VARCHAR(150) = NULL,
@NetworkCabinet VARCHAR(150) = NULL,
@NetworkBlade VARCHAR(150) = NULL,
@NetworkSerial VARCHAR(150) = NULL,
@NetworkILOIP VARCHAR(150) = NULL,
@NetworkILOLIC VARCHAR(150) = NULL,
@NetworkIP3 VARCHAR(150) = NULL,
@NetworkLocation VARCHAR(150) = NULL,
@NetworkNet VARCHAR(150) = NULL,
@NetworkChassis VARCHAR(150) = NULL,
@NetworkModel VARCHAR(150) = NULL,
@NetworkGeneration VARCHAR(150) = NULL,
@NetworkILODNS VARCHAR(150) = NULL,
@NetworkIP2 VARCHAR(150) = NULL,
@NotesComments VARCHAR(2000) = NULL,
@NewServerID INTEGER OUTPUT
)
AS

SET NOCOUNT ON
	
INSERT INTO Servers
(
[Name],
Type,
Location,
IPAddress,
IIS,
DBMS,
DBAAssigned,
AdminEngineer,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
InstallationSpecialInstructions,
HardwareSpecs,
BackupSchedule,
NetworkGroup,
NetworkDescription,
NetworkCabinet,
NetworkBlade,
NetworkSerial,
NetworkILOIP,
NetworkILOLIC,
NetworkIP3,
NetworkLocation,
NetworkNet,
NetworkChassis,
NetworkModel,
NetworkGeneration,
NetworkILODNS,
NetworkIP2,
NotesComments
)

VALUES 
(
@Name,
@ServerType,
@Location,
@IPAddress,
@IIS,
@DBMS,
@DBAAssigned,
@AdminEngineer,
@StartupInstructions,
@ShutdownInstructions,
@SoftwareSpecs,
@InstallationSpecialInstructions,
@HardwareSpecs,
@BackupSchedule,
@NetworkGroup,
@NetworkDescription,
@NetworkCabinet,
@NetworkBlade,
@NetworkSerial,
@NetworkILOIP,
@NetworkILOLIC,
@NetworkIP3,
@NetworkLocation,
@NetworkNet,
@NetworkChassis,
@NetworkModel,
@NetworkGeneration,
@NetworkILODNS,
@NetworkIP2,
@NotesComments
)

SELECT @NewServerID = @@IDENTITY







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_InsertApplications]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_InsertApplications
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/19/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_InsertApplications]
(
@ServerID INT,
@ApplicationArray CHAR(4096)
)
AS

SET NOCOUNT ON

DECLARE @intPrevIndex INT
DECLARE @intIndex INT
DECLARE @intTotalLen INT
DECLARE @intLen INT
DECLARE @strData VARCHAR(10)
DECLARE @intData INT
DECLARE @intLengthCount INT
DECLARE @ReturnCode INT

SET @intPrevIndex = 1
SET @intIndex = 0
SET @ReturnCode = 0

--Find the actual length of data passed in stream
SET @intTotalLen = LEN(RTRIM(@ApplicationArray)) 
SET @intLengthCount = 0
SET @intLen = 0

DELETE FROM Installations
WHERE ServerID = @ServerID

SELECT @ReturnCode = @@ERROR

WHILE (@intLengthCount < @intTotalLen) AND @ReturnCode = 0
	BEGIN
		--if @intIndex is 0, then no delimiter was found
		SELECT @intIndex = CHARINDEX(',', @ApplicationArray, @intPrevIndex) 

		IF @intIndex > 0
			BEGIN
				-- the length of the data to extract
				SET @intLen = @intIndex - @intPrevIndex
				SET @strData = SUBSTRING(@ApplicationArray, @intPrevIndex, @intLen)
				SELECT @strData = LTRIM(RTRIM(@strData)) 

				IF LEN(@strData) > 0
					BEGIN
						SELECT @intData = CAST(@strData AS INT)

						INSERT INTO Installations (
							ServerID, 
							ApplicationID)
						VALUES  (
							@ServerID,
							@intData)
					END
				
				 --get position after delimiter
				SET @intPrevIndex = @intIndex + 1
				SET @intLengthCount = @intLengthCount + @intLen + 1
			END
		ELSE	--This will either be the first record of just one ID in the array OR the last record of more than one ID in the array
			BEGIN
				SET @strData = SUBSTRING(@ApplicationArray, @intPrevIndex, 20)
				SELECT @strData = LTRIM(RTRIM(@strData)) 

				IF LEN(@strData) > 0
					BEGIN
						SELECT @intData = CAST(@strData AS INT)

						INSERT INTO Installations (
							ServerID, 
							ApplicationID)
						VALUES  (
							@ServerID,
							@intData)
					END
				
				SET @intLengthCount = @intLengthCount + @intTotalLen + 1
			END				
	END







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_InsertDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************
	Name:		usp_Server_InsertDocument
	Desc:		

	Author:		Catalyst Software Solutions - Arnold Smith
	Created Date:	9-15-2005
	
	History: 
 
	Who:			When:		What:
	------------------------------------------------------------------------------
	
*******************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_InsertDocument]
(
@ServerID INTEGER,
@DocName VARCHAR(200),
@DocPath VARCHAR(255)
)
AS

SET NOCOUNT ON

INSERT INTO ServerDocuments
(
ServerID,
DocName,
DocPath
) 
VALUES 
(
@ServerID,
@DocName,
@DocPath
)







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_LookForDuplicateName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_LookForDuplicateName
**		Desc: Check if the Name already exists on a record.
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/23/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_LookForDuplicateName]
(
@Name VARCHAR(150),
@ServerID INTEGER
)
AS

SET NOCOUNT ON

IF @ServerID > 0
	BEGIN	
		SELECT Count(*)
		FROM Servers
		WHERE [Name] = @Name
		AND ServerID <> @ServerID
	END
ELSE
	BEGIN
		SELECT Count(*)
		FROM Servers
		WHERE [Name] = @Name
	END






GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectAll]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectAll
**		Desc: Select all records from the Servers table
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectAll]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
dbo.udf_AppForServer(ServerID, @ApplicationID) AS ApplicationServerRelation,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule,
NotesComments
FROM Servers
ORDER BY ApplicationServerRelation DESC, [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/******************************************************************************
**		File: 
**		Name: usp_Server_SelectByCriteria
**		Desc: 
**
**		This template can be customized:
**              
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/12/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE Procedure  [dbo].[usp_Server_SelectByCriteria]
(
@Name VARCHAR(150) = '%',
@Location VARCHAR(150) = '%',
@IPAddress VARCHAR(150) = '%',
@Type INTEGER = 99,
@ServerEngineer VARCHAR(150) = '%'
)

AS
BEGIN

SET NOCOUNT ON

IF @Type = 99
	BEGIN
		SELECT
		ServerID,
		Type,
		dbo.udf_GetServerType(Type) AS ServerType,
		StartupInstructions,
		ShutdownInstructions,
		SoftwareSpecs,
		[Name],
		Location,
		IPAddress,
		IIS,
		InstallationSpecialInstructions,
		HardwareSpecs,
		DBMS,
		DBAAssigned,
		AdminEngineer,
		BackupSchedule,
		NotesComments
		FROM Servers
		WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)
		AND (Location LIKE '%' + @Location + '%' OR Location IS NULL)
		AND (IPAddress LIKE '%' + @IPAddress + '%'	OR IPAddress IS NULL)
		AND (AdminEngineer LIKE '%' + @ServerEngineer + '%'	OR AdminEngineer IS NULL)
		ORDER BY [Name]
	END
ELSE
	BEGIN
		SELECT
		ServerID,
		Type,
		dbo.udf_GetServerType(Type) AS ServerType,
		StartupInstructions,
		ShutdownInstructions,
		SoftwareSpecs,
		[Name],
		Location,
		IPAddress,
		IIS,
		InstallationSpecialInstructions,
		HardwareSpecs,
		DBMS,
		DBAAssigned,
		AdminEngineer,
		BackupSchedule,
		NotesComments
		FROM Servers
		WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)
		AND (Location LIKE '%' + @Location + '%' OR Location IS NULL)
		AND (IPAddress LIKE '%' + @IPAddress + '%'	OR IPAddress IS NULL)
		AND (AdminEngineer LIKE '%' + @ServerEngineer + '%'	OR AdminEngineer IS NULL)
		AND Type = @Type
		ORDER BY [Name]
	END
END






GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectByID]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectByID
**		Desc: Select a record from the Servers table by ServerID
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectByID]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule,
NotesComments
FROM Servers
WHERE ServerID = @ServerID







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectByName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectByName
**		Desc: Select record from the Servers table by Name
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectByName]
(
@Name VARCHAR(150)
)
AS

SET NOCOUNT ON
	
SELECT
ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule,
NotesComments
FROM Servers
WHERE ([Name] LIKE '%' + @Name + '%' OR [Name] IS NULL)







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectDocuments]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectDocuments
**		Desc: 
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/15/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectDocuments]
(
@ServerID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
DocID, 
DocName, 
DocPath 
FROM ServerDocuments
WHERE ServerID = @ServerID
ORDER BY DocName






GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectForApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectForApplication
**		Desc: Select all Servers records for an application
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectForApplication]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
Servers.ServerID,
Type,
dbo.udf_GetServerType(Type) AS ServerType,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule,
NotesComments
FROM Servers, Installations
WHERE Servers.ServerID = Installations.ServerID
AND ApplicationID = @ApplicationID
ORDER BY [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectNotForApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectNotForApplication
**		Desc: Select all Servers records not already associated with an application
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectNotForApplication]
(
@ApplicationID INTEGER
)
AS

SET NOCOUNT ON
	
SELECT
Servers.ServerID,
Type,
StartupInstructions,
ShutdownInstructions,
SoftwareSpecs,
[Name],
Location,
IPAddress,
IIS,
InstallationSpecialInstructions,
HardwareSpecs,
DBMS,
DBAAssigned,
AdminEngineer,
BackupSchedule,
NotesComments
FROM Servers, Installations
WHERE Servers.ServerID = Installations.ServerID
AND ApplicationID <> @ApplicationID
ORDER BY [Name]







GO
/****** Object:  StoredProcedure [dbo].[usp_Server_SelectServerTypes]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_SelectServerTypes
**		Desc: Select a record from the Servers table by ServerID
**
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_SelectServerTypes]

AS

SET NOCOUNT ON
	
SELECT
ServerTypeID,
ServerType
FROM ServerTypes
ORDER BY ServerType






GO
/****** Object:  StoredProcedure [dbo].[usp_Server_Update]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		Name: usp_Server_Update
**		Desc: Update a record into the Servers table
**
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 8/22/2005
**      Updated: 10/10/2005 - added the network entries to the list  Alvin Ross
**    
*******************************************************************************/
CREATE PROCEDURE [dbo].[usp_Server_Update]
(
@ServerID INTEGER,
@Name VARCHAR(150) = NULL,
@ServerType INTEGER = NULL,
@Location VARCHAR(150) = NULL,
@IPAddress VARCHAR(150) = NULL,
@IIS VARCHAR(150) = BIT,
@DBMS VARCHAR(150) = NULL,
@DBAAssigned VARCHAR(150) = NULL,
@AdminEngineer VARCHAR(150) = NULL,
@StartupInstructions VARCHAR(150) = NULL,
@ShutdownInstructions VARCHAR(150) = NULL,
@SoftwareSpecs VARCHAR(150) = NULL,
@InstallationSpecialInstructions VARCHAR(2000) = NULL,
@HardwareSpecs VARCHAR(150) = NULL,
@BackupSchedule VARCHAR(150) = NULL,
@NetworkGroup VARCHAR(150) = NULL,
@NetworkDescription VARCHAR(150) = NULL,
@NetworkCabinet VARCHAR(150) = NULL,
@NetworkBlade VARCHAR(150) = NULL,
@NetworkSerial VARCHAR(150) = NULL,
@NetworkILOIP VARCHAR(150) = NULL,
@NetworkILOLIC VARCHAR(150) = NULL,
@NetworkIP3 VARCHAR(150) = NULL,
@NetworkLocation VARCHAR(150) = NULL,
@NetworkNet VARCHAR(150) = NULL,
@NetworkChassis VARCHAR(150) = NULL,
@NetworkModel VARCHAR(150) = NULL,
@NetworkGeneration VARCHAR(150) = NULL,
@NetworkILODNS VARCHAR(150) = NULL,
@NetworkIP2 VARCHAR(150) = NULL,
@NotesComments VARCHAR(2000) = NULL
)
AS

SET NOCOUNT ON
	
UPDATE Servers
SET 
Type = @ServerType,
StartupInstructions = @StartupInstructions,
ShutdownInstructions = @ShutdownInstructions,
SoftwareSpecs = @SoftwareSpecs,
[Name] = @Name,
Location = @Location,
IPAddress = @IPAddress,
IIS = @IIS,
InstallationSpecialInstructions = @InstallationSpecialInstructions,
HardwareSpecs = @HardwareSpecs,
DBMS = @DBMS,
DBAAssigned = @DBAAssigned,
AdminEngineer = @AdminEngineer,
BackupSchedule = @BackupSchedule,
NetworkGroup = @NetworkGroup,
NetworkDescription = @NetworkDescription,
NetworkCabinet = @NetworkCabinet,
NetworkBlade = @NetworkBlade,
NetworkSerial = @NetworkSerial,
NetworkILOIP = @NetworkILOIP,
NetworkILOLIC = @NetworkILOLIC,
NetworkIP3 = @NetworkIP3,
NetworkLocation = @NetworkLocation,
NetworkNet = @NetworkNet,
NetworkChassis = @NetworkChassis,
NetworkModel = @NetworkModel,
NetworkGeneration = @NetworkGeneration,
NetworkILODNS = @NetworkILODNS,
NetworkIP2 = @NetworkIP2,
NotesComments = @NotesComments
WHERE ServerID = @ServerID







GO
/****** Object:  StoredProcedure [dbo].[usp_ServerLookForDuplicateName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ServerLookForDuplicateName]
(
@Name VARCHAR(150),
@ServerID INTEGER
)
AS

SET NOCOUNT ON

IF @ServerID > 0
	BEGIN	
		SELECT Count(*)
		FROM Server
		WHERE [Name] = @Name
		AND ServerID <> @ServerID
	END
ELSE
	BEGIN
		SELECT Count(*)
		FROM Server
		WHERE [Name] = @Name
	END





GO
/****** Object:  StoredProcedure [dbo].[usp_ServerSelectByCriteria]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
**		File: 
**		Name: usp_Server_SelectByCriteria
**		Desc: 
**
**		This template can be customized:
**              
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------							-----------
**
**		Auth: Catalyst Software Solutions - Arnold Smith
**		Date: 9/12/2005
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------		--------				-------------------------------------------
**    
*******************************************************************************/
CREATE Procedure [dbo].[usp_ServerSelectByCriteria]
(
	@Name VARCHAR(150) = '%',
	@IPAddress VARCHAR(150) = '%',
	@TypeID INT = 99,
	@UseID INT = 99,
	@ITGroupID INT = 0,
	@AdminEngineerID INT = 0
)
AS
DECLARE @sSql varchar(2000)
DECLARE @sCondition varchar(500)

BEGIN

SET NOCOUNT ON

IF(@TypeID = 99 AND @UseID = 99)
	BEGIN
		SET @sCondition = ''
	END
IF(@TypeID = 99 AND @UseID <> 99)
	BEGIN
		SET @sCondition = ' AND (ServerUseID = CASE ' + CONVERT(varchar(5),@UseID) + ' WHEN 0 THEN ServerUseID ELSE ' + CONVERT(varchar(5),@UseID)  + ' END)'
	END
IF(@UseID = 99 AND @TypeID <> 99)
	BEGIN
		SET @sCondition = ' AND (ServerTypeID = CASE ' + CONVERT(varchar(5),@TypeID) + ' WHEN 0 THEN ServerTypeID ELSE ' + CONVERT(varchar(5),@TypeID) + ' END)'
	END
IF(@UseID <> 99 AND @TypeID <> 99)
	BEGIN
		SET @sCondition = ' AND (ServerUseID = CASE ' + CONVERT(varchar(5),@UseID) + ' WHEN 0 THEN ServerUseID ELSE ' + CONVERT(varchar(5),@UseID)  + ' END)'
						+  ' AND (ServerTypeID = CASE ' + CONVERT(varchar(5),@TypeID) + ' WHEN 0 THEN ServerTypeID ELSE ' + CONVERT(varchar(5),@TypeID) + ' END)'
	END

SET @sSql = 'SELECT 
				ServerID,
				ServerTypeID as Type, 
				IsNull(lkpServerType.Description, ' + char(39) + char(39) + ') as ServerType,
				IsNull(lkpServerUse.Description, ' + char(39) + char(39) + ') as ServerUse, 
				[Name], 
				IsNull(lkpLocation.Description, ' + char(39) + char(39) + ') as Location,
				IPAddress, 
				lkpAdminEngineer.Description as AdminEngineer, 
				lkpITGroup.Description as ITGroup, 
				Comment
				FROM Server
				LEFT JOIN lkpAdminEngineer (NOLOCK) ON AdminEngineerID = lkpAdminEngineer.LookupID
				LEFT JOIN lkpServerType (NOLOCK) ON ServerTypeID = lkpServerType.LookupID
				LEFT JOIN lkpServerUse (NOLOCK) ON ServerUseID = lkpServerUse.LookupID
				LEFT JOIN lkpLocation (NOLOCK) ON LocationID = lkpLocation.LookupID
				LEFT JOIN lkpITGroup (NOLOCK) ON ITGroupID = lkpITGroup.LookupID
				WHERE ([Name] LIKE ' + char(39) + '%' +   @Name + '%' + char(39) + ' OR [Name] IS NULL)
				AND (IPAddress LIKE ' + char(39) + '%' + @IPAddress + '%' + char(39) + ' OR  IPAddress IS NULL)
				AND (ITGroupID = CASE ' +  CONVERT(varchar(5),@ITGroupID) + ' WHEN 0 THEN ITGroupID ELSE ' + CONVERT(varchar(5),@ITGroupID) + ' END) 
				AND (AdminEngineerID = CASE ' + CONVERT(varchar(5),@AdminEngineerID) + ' WHEN 0 THEN AdminEngineerID ELSE ' + CONVERT(varchar(5),@AdminEngineerID)  + ' END)'
				+ @sCondition
				+ ' ORDER BY [Name]'

exec(@sSql)



END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_UpdateADGroup]
	@GroupName VARCHAR(255),
	@GroupPath VARCHAR(255),
	@ADGroupID INT
AS
BEGIN
	UPDATE ADGroup SET
		GroupName = @GroupName,
		GroupPath = @GroupPath
	WHERE ADGroupID = @ADGroupID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateComment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateComment]
	@ParentID INT,
	@Comment TEXT,
	@CommentID INT,
	@DateEntered DATETIME,
	@ParentType VARCHAR(10),
	@EnteredBy VARCHAR(100)
AS
BEGIN
	UPDATE Comment SET
		ParentID = @ParentID,
		Comment = @Comment,
		DateEntered = @DateEntered,
		ParentType = @ParentType,
		EnteredBy = @EnteredBy
	WHERE CommentID = @CommentID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCommunity]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UpdateCommunity]
	@CommunityTypeID INT,
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreatedDate DATETIME,
	@Name VARCHAR(50),
	@CommunityID INT,
	@CommunityAdminID VARCHAR(50),
	@IsVisibleInsideGGP BIT
AS
BEGIN
	UPDATE Community SET
		CommunityTypeID = @CommunityTypeID,
		LastUpdated = @LastUpdated,
		LastUpdatedBy = @LastUpdatedBy,
		Description = @Description,
		URL = @URL,
		CreatedDate = @CreatedDate,
		Name = @Name,
		CommunityAdminID = @CommunityAdminID,
		IsVisibleInsideGGP = @IsVisibleInsideGGP
	WHERE CommunityID = @CommunityID
END






GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateContact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateContact]
	@LastName VARCHAR(50),
	@ContactTypeID INT,
	@FirstName VARCHAR(50),
	@MiddleInitial VARCHAR(1),
	@EmployeeNo VARCHAR(50),
	@SID VARCHAR(50),
	@IsValid BIT,
	@Email VARCHAR(50),
	@Phone VARCHAR(100),
	@ContactID INT,
	@Title VARCHAR(100),
	@LoginName VARCHAR(50)
AS
BEGIN
	UPDATE Contact SET
		LastName = @LastName,
		ContactTypeID = @ContactTypeID,
		FirstName = @FirstName,
		MiddleInitial = @MiddleInitial,
		EmployeeNo = @EmployeeNo,
		SID = @SID,
		IsValid = @IsValid,
		Email = @Email,
		Phone = @Phone,
		Title = @Title,
		LoginName = @LoginName
	WHERE ContactID = @ContactID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UpdateDatabase]
	@LastUpdatedBy VARCHAR(100),
	@ServicePack VARCHAR(50),
	@InstalledDate DATETIME,
	@IsTestDB BIT,
	@IsDevDB BIT,
	@DBTypeID INT,
	@LastUpdated DATETIME,
	@Name VARCHAR(100),
	@Comments VARCHAR(1000),
	@DatabaseID INT,
	@IsProdDB BIT,
	@DBVersion VARCHAR(50)	
AS
BEGIN
	UPDATE Databases SET
		LastUpdatedBy = @LastUpdatedBy,
		ServicePack = @ServicePack,
		InstalledDate = @InstalledDate,
		IsTestDB = @IsTestDB,
		IsDevDB = @IsDevDB,
		DBTypeID = @DBTypeID,
		LastUpdated = @LastUpdated,
		Name = @Name,
		Comments = @Comments,
		IsProdDB = @IsProdDB,
		DBVersion = @DBVersion	
	WHERE DatabaseID = @DatabaseID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateDesktop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateDesktop]
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreatedDate DATETIME,
	@Name VARCHAR(50),
	@DesktopID INT,
	@DesktopAdminID VARCHAR(50)
AS
BEGIN
	UPDATE Desktop SET
		LastUpdated = @LastUpdated,
		LastUpdatedBy = @LastUpdatedBy,
		Description = @Description,
		URL = @URL,
		CreateDate = @CreatedDate,
		Name = @Name,
		DesktopAdminID = @DesktopAdminID
	WHERE DesktopID = @DesktopID
END




GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateDocument]
	@Name VARCHAR(255),
	@Path VARCHAR(500),
	@DocumentID INT
AS
BEGIN
	UPDATE Document SET
		Name = @Name,
		Path = @Path
	WHERE DocumentID = @DocumentID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateGGPDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateGGPDeveloper]
	@LeadDeveloper VARCHAR(200),
	@GGPDeveloperID INT,
	@ProgrammingLanguageID INT,
	@BusinessAnalyst VARCHAR(200)
AS
BEGIN
	UPDATE GGPDeveloper SET
		LeadDeveloper = @LeadDeveloper,
		ProgrammingLanguageID = @ProgrammingLanguageID,
		BusinessAnalyst = @BusinessAnalyst
	WHERE GGPDeveloperID = @GGPDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateOutsideDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UpdateOutsideDeveloper]
	@OutsideDeveloperID INT,
	@ContactID INT,
	@CompanyName VARCHAR(100)
AS
BEGIN
	UPDATE OutsideDeveloper SET
		ContactID = @ContactID,
		CompanyName = @CompanyName
	WHERE OutsideDeveloperID = @OutsideDeveloperID
END





GO
/****** Object:  StoredProcedure [dbo].[usp_UpdatePortalSite]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UpdatePortalSite]
	@LastUpdated DATETIME,
	@LastUpdatedBy VARCHAR(100),
	@Description VARCHAR(500),
	@URL VARCHAR(500),
	@CreateDate DATETIME,
	@Name VARCHAR(50),
	@PortalSiteID INT,
	@PortalAdminID VARCHAR(50)	
AS
BEGIN
	UPDATE PortalSites SET		
		LastUpdated = @LastUpdated,
		LastUpdatedBy = @LastUpdatedBy,
		Description = @Description,
		URL = @URL,
		CreateDate = @CreateDate,
		Name = @Name,
		PortalAdminID = @PortalAdminID		
	WHERE PortalSiteID = @PortalSiteID
END






GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UpdateServer]
	@IPAddress VARCHAR(40),
	@GroupDescription VARCHAR(500),
	@RebootSchedule VARCHAR(500),
	@AdminEngineerID INT,
	@NetworkTypeID INT,
	@ProcessorNumber INT,
	@IPAddress2 VARCHAR(40),
	@LastUpdated DATETIME,
	@WebServerTypeID INT,
	@VirtualHostType INT,
	@ControllerNumber INT,
	@ILODNSName VARCHAR(50),
	@ITGroupID INT,
	@DiskCapacity VARCHAR(50),
	@BackupPath VARCHAR(500),
	@ServerMemory VARCHAR(50),
	@LocationID INT,
	@ServerID INT,
	@AntiVirusTypeID INT,
	@ServerTypeID INT,
	@ServerUseID INT,
	@BackupDescription VARCHAR(500),
	@OS INT,
	@BladeNo VARCHAR(50),
	@Generation VARCHAR(50),
	@CabinetNo VARCHAR(50),
	@ILOLicense VARCHAR(100),
	@CPUSpeed VARCHAR(50),
	@VHostName VARCHAR(50),
	@ModelNo VARCHAR(50),
	@Name VARCHAR(50),
	@Comment TEXT,
	@LastUpdatedBy VARCHAR(100),
	@SerialNo VARCHAR(50),
	@ILOIPAddress VARCHAR(40),
	@ChasisNo VARCHAR(50),
	@IPAddress3 VARCHAR(40),
    @IPAddress4 VARCHAR(40),
	@SAN VARCHAR(40),
   	@SANSwitchName VARCHAR(40),
    @SANSwitchPort  VARCHAR(40),
    @FibreBackup  VARCHAR(40),
    @FibreSwitchName  VARCHAR(40),
    @FibreSwitchPort  VARCHAR(40),
	@ClusterType  VARCHAR(40),
	@ClusterName  VARCHAR(40),
	@ClusterIP1  VARCHAR(40),
            @ClusterIP2  VARCHAR(40),
            @ManufacturerNumber  VARCHAR(40),
            @Manufacturer  VARCHAR(40),
            @NIC1Bundle  VARCHAR(40),
            @NIC2Bundle  VARCHAR(40),
            @NIC3Bundle  VARCHAR(40),
            @NIC4Bundle  VARCHAR(40),
            @NIC1Cable  VARCHAR(40),
            @NIC2Cable  VARCHAR(40),
            @NIC3Cable  VARCHAR(40),
            @NIC4Cable  VARCHAR(40),
            @ClusterSAN  VARCHAR(40),
            @LUNNumber  VARCHAR(40),    
            @WarrantyExpiration  VARCHAR(40),
	@SMTP BIT,
@NIC1Interface VARCHAR(600),
      @NIC2Interface VARCHAR(600),
      @NIC3Interface VARCHAR(600),
      @NIC4Interface VARCHAR(600),
      @NIC1Subnet VARCHAR(600),
      @NIC2Subnet VARCHAR(600),
      @NIC3Subnet VARCHAR(600),
      @NIC4Subnet VARCHAR(600),
      @NIC1SwitchPortNum VARCHAR(600),
      @NIC2SwitchPortNum VARCHAR(600),
      @NIC3SwitchPortNum VARCHAR(600),
      @NIC4SwitchPortNum VARCHAR(600),
      @NIC1VLAN INT,
      @NIC2VLAN INT,
      @NIC3VLAN INT,
      @NIC4VLAN INT,
      @NIC1SwitchName INT,
      @NIC2SwitchName INT,
      @NIC3SwitchName INT,
      @NIC4SwitchName INT,
      @CPUType VARCHAR(600),
      @DNSServer1 VARCHAR(600),
      @DNSServer2 VARCHAR(600),
      @PhysicalDiskSize VARCHAR(600),
      @PhysicalDisks INT,
      @RaidType INT,
      @Partition1DriveName VARCHAR(600),
      @Partition2DriveName VARCHAR(600),
      @Partition3DriveName VARCHAR(600),
      @Partition4DriveName VARCHAR(600),
      @Partition5DriveName VARCHAR(600),
      @Partition6DriveName VARCHAR(600),
      @Partition7DriveName VARCHAR(600),
      @Partition8DriveName VARCHAR(600),
      @Partition9DriveName VARCHAR(600),
      @Partition10DriveName VARCHAR(600),
      @VPartition1DriveName VARCHAR(600),
      @VPartition2DriveName VARCHAR(600),
      @VPartition3DriveName VARCHAR(600),
      @VPartition4DriveName VARCHAR(600),
      @VPartition5DriveName VARCHAR(600),
      @VPartition6DriveName VARCHAR(600),
      @VPartition7DriveName VARCHAR(600),
      @VPartition8DriveName VARCHAR(600),
      @VPartition9DriveName VARCHAR(600),
      @VPartition10DriveName VARCHAR(600),
      @Partition1Size VARCHAR(600),
      @Partition2Size VARCHAR(600),
      @Partition3Size VARCHAR(600),
      @Partition4Size VARCHAR(600),
      @Partition5Size VARCHAR(600),
      @Partition6Size VARCHAR(600),
      @Partition7Size VARCHAR(600),
      @Partition8Size VARCHAR(600),
      @Partition9Size VARCHAR(600),
      @Partition10Size VARCHAR(600),
      @VPartition1Size VARCHAR(600),
      @VPartition2Size VARCHAR(600),
      @VPartition3Size VARCHAR(600),
      @VPartition4Size VARCHAR(600),
      @VPartition5Size VARCHAR(600),
      @VPartition6Size VARCHAR(600),
      @VPartition7Size VARCHAR(600),
      @VPartition8Size VARCHAR(600),
      @VPartition9Size VARCHAR(600),
      @VPartition10Size VARCHAR(600),
      @Ownership INT,
      @NumPartitions INT,
      @VNumPartitions INT,
      @ILOPassword VARCHAR(600)   
AS
BEGIN
	UPDATE Server SET
		IPAddress = @IPAddress,
		GroupDescription = @GroupDescription,
		RebootSchedule = @RebootSchedule,
		AdminEngineerID = @AdminEngineerID,
		NetworkTypeID = @NetworkTypeID,
		ProcessorNumber = @ProcessorNumber,
		IPAddress2 = @IPAddress2,
		LastUpdated = @LastUpdated,
		WebServerTypeID = @WebServerTypeID,
		VirtualHostType = @VirtualHostType,
		ControllerNumber = @ControllerNumber,
		ILODNSName = @ILODNSName,
		ITGroupID = @ITGroupID,
		DiskCapacity = @DiskCapacity,
		BackupPath = @BackupPath,
		ServerMemory = @ServerMemory,
		LocationID = @LocationID,
		AntiVirusTypeID = @AntiVirusTypeID,
		ServerTypeID = @ServerTypeID,
		ServerUseID = @ServerUseID,
		BackupDescription = @BackupDescription,
		OS = @OS,
		BladeNo = @BladeNo,
		Generation = @Generation,
		CabinetNo = @CabinetNo,
		ILOLicense = @ILOLicense,
		CPUSpeed = @CPUSpeed,
		VHostName = @VHostName,
		ModelNo = @ModelNo,
		Name = @Name,
		Comment = @Comment,
		LastUpdatedBy = @LastUpdatedBy,
		SerialNo = @SerialNo,
		ILOIPAddress = @ILOIPAddress,
		ChasisNo = @ChasisNo,
		IPAddress3 = @IPAddress3,
       	IPAddress4 = @IPAddress4,
		SANSwitchName = @SANSwitchName, 
	   	SANSwitchPort = @SANSwitchPort,  
	    FibreBAckup = @FibreBackup,  
	    FibreSwitchName = @FibreSwitchName, 
	    FibreSwitchPort = @FibreSwitchPort,  
		ClusterType = @ClusterType,  
		ClusterName = @ClusterName,  
		ClusterIP1 = @ClusterIP1,  
	    ClusterIP2 = @ClusterIP2, 
	    ManufacturerNumber = @ManufacturerNumber,  
	    Manufacturer = @Manufacturer,  
	    NIC1Bundle = @NIC1Bundle,  
	    NIC2Bundle = @NIC2Bundle,  
	    NIC3Bundle = @NIC3Bundle,  
	    NIC4Bundle = @NIC4Bundle,  
	    NIC1Cable = @NIC1Cable,  
	    NIC2Cable = @NIC2Cable,  
	    NIC3Cable = @NIC3Cable,  
	    NIC4CAble = @NIC4Cable,  
	    ClusterSAN = @ClusterSAN,  
	    LUNNumber = @LUNNumber, 
	    WarrantyExpiration = @WarrantyExpiration,
		SMTP = @SMTP, 
      NIC1Interface = @NIC1Interface,
      NIC2Interface = @NIC2Interface,
      NIC3Interface= @NIC3Interface,
      NIC4Interface= @NIC4Interface,
      NIC1Subnet = @NIC1Subnet,
      NIC2Subnet = @NIC2Subnet,
      NIC3Subnet = @NIC3Subnet,
      NIC4Subnet= @NIC4Subnet,
      NIC1SwitchPortNum = @NIC1SwitchPortNum,
      NIC2SwitchPortNum = @NIC2SwitchPortNum,
      NIC3SwitchPortNum = @NIC3SwitchPortNum,
      NIC4SwitchPortNum = @NIC4SwitchPortNum,
      NIC1VLAN = @NIC1VLAN,
      NIC2VLAN = @NIC2VLAN,
      NIC3VLAN = @NIC3VLAN,
      NIC4VLAN = @NIC4VLAN,
      NIC1SwitchName = @NIC1SwitchName,
      NIC2SwitchName = @NIC2SwitchName,
      NIC3SwitchName = @NIC3SwitchName,
      NIC4SwitchName = @NIC4SwitchName,
      CPUType = @CPUType,
      DNSServer1 = @DNSServer1,
      DNSServer2 = @DNSServer2,
      PhysicalDiskSize = @PhysicalDiskSize,
      PhysicalDisks = @PhysicalDisks,
      RaidType = @RaidType,
      Partition1DriveName = @Partition1DriveName,
      Partition2DriveName = @Partition2DriveName,
      Partition3DriveName = @Partition3DriveName,
      Partition4DriveName = @Partition4DriveName,
      Partition5DriveName = @Partition5DriveName,
      Partition6DriveName = @Partition6DriveName,
      Partition7DriveName = @Partition7DriveName,
      Partition8DriveName = @Partition8DriveName,
      Partition9DriveName = @Partition9DriveName,
      Partition10DriveName = @Partition10DriveName,
      VPartition1DriveName = @VPartition1DriveName,
      VPartition2DriveName = @VPartition2DriveName,
      VPartition3DriveName = @VPartition3DriveName,
      VPartition4DriveName = @VPartition4DriveName,
      VPartition5DriveName = @VPartition5DriveName,
      VPartition6DriveName = @VPartition6DriveName,
      VPartition7DriveName = @VPartition7DriveName,
      VPartition8DriveName = @VPartition8DriveName,
      VPartition9DriveName = @VPartition9DriveName,
      VPartition10DriveName = @VPartition10DriveName,
      Partition1Size = @Partition1Size,
      Partition2Size = @Partition2Size,
      Partition3Size = @Partition3Size,
      Partition4Size = @Partition4Size,
      Partition5Size = @Partition5Size,
      Partition6Size = @Partition6Size,
      Partition7Size= @Partition7Size,
      Partition8Size = @Partition8Size,
      Partition9Size = @Partition9Size,
      Partition10Size = @Partition10Size,
      VPartition1Size = @VPartition1Size,
      VPartition2Size = @VPartition2Size,
      VPartition3Size = @VPartition3Size,
      VPartition4Size = @VPartition4Size,
      VPartition5Size = @VPartition5Size,
      VPartition6Size = @VPartition6Size,
      VPartition7Size = @VPartition7Size,
      VPartition8Size = @VPartition8Size,
      VPartition9Size = @VPartition9Size,
      VPartition10Size = @VPartition10Size,
      Ownership = @Ownership,
      NumPartitions = @NumPartitions,
      VNumPartitions = @VNumPartitions,
      ILOPassword = @ILOPassword
	WHERE ServerID = @ServerID
END





GO
/****** Object:  UserDefinedFunction [dbo].[udf_AppForServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[udf_AppForServer]
(
@ServerID INTEGER,
@ApplicationID INTEGER
)
Returns BIT

AS

BEGIN

	DECLARE @Count INTEGER
	DECLARE @Return BIT

	SELECT @Count = Count(*) 
	FROM Installations 
	WHERE ServerID = @ServerID
	AND ApplicationID = @ApplicationID

	IF @Count > 0
		SET @Return = -1
	ELSE
		SET @Return = 0
		
	RETURN @Return		
	
END 




GO
/****** Object:  UserDefinedFunction [dbo].[udf_ApplicationServerRelation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[udf_ApplicationServerRelation]
(
@ServerID INTEGER,
@ApplicationID INTEGER
)

Returns BIT

AS

BEGIN

	DECLARE @Count INTEGER
	DECLARE @Return BIT

	IF @ServerID > 0
		BEGIN
			SELECT @Count = Count(ApplicationID) 
			FROM Installations 
			WHERE ServerID = @ServerID
		END 
	ELSE
		BEGIN
			SELECT @Count = Count(ServerID) 
			FROM Installations WHERE 
			ApplicationID = @ApplicationID
		END 

	IF @Count > 0
		SET @Return = 1
	ELSE
		SET @Return = 0
		
	RETURN @Return		
	
END




GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetServerType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE Function [dbo].[udf_GetServerType]
(
@ServerTypeID INT
)

Returns VARCHAR(20) AS



BEGIN
	DECLARE @ServerType  VARCHAR(20)
	SELECT @ServerType = ServerType FROM ServerTypes WHERE ServerTypeID = @ServerTypeID
	RETURN @ServerType
END 







GO
/****** Object:  UserDefinedFunction [dbo].[udf_ServerForApp]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[udf_ServerForApp]
(
@ApplicationID INTEGER,
@ServerID INTEGER
)
Returns BIT

AS

BEGIN

	DECLARE @Count INTEGER
	DECLARE @Return BIT

	SELECT @Count = Count(*) 
	FROM Installations 
	WHERE ApplicationID = @ApplicationID
	AND ServerID = @ServerID

	IF @Count > 0
		SET @Return = -1
	ELSE
		SET @Return = 0
		
	RETURN @Return		
	
END  




GO
/****** Object:  Table [dbo].[__EFMigrationsHistory]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[__EFMigrationsHistory](
	[MigrationId] [nvarchar](150) NOT NULL,
	[ProductVersion] [nvarchar](32) NOT NULL,
 CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY CLUSTERED 
(
	[MigrationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ADGroup](
	[ADGroupID] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](255) NULL,
	[GroupPath] [varchar](255) NULL,
 CONSTRAINT [PK_ADGroup] PRIMARY KEY CLUSTERED 
(
	[ADGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ADGroupExclude]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ADGroupExclude](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](255) NULL,
	[GroupPath] [varchar](255) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Application]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Application](
	[ApplicationID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Ver] [varchar](20) NULL,
	[ShortDescription] [varchar](100) NOT NULL,
	[LongDescription] [varchar](500) NULL,
	[InstallationPath] [varchar](500) NULL,
	[InstalledDate] [datetime] NULL,
	[SupportPhone] [varchar](100) NULL,
	[SupportEmail] [varchar](100) NULL,
	[SupportAccountNo] [varchar](50) NULL,
	[SupportExpirationDate] [datetime] NULL,
	[SupportURL] [varchar](200) NULL,
	[NumberOfLicenses] [int] NULL,
	[Comment] [varchar](1000) NULL,
	[InstallerNameID] [int] NULL,
	[Usrname] [varchar](100) NULL,
	[Pass] [varchar](100) NULL,
	[DeveloperTypeID] [int] NULL,
	[DeveloperID] [int] NULL,
	[CitrixApplicationName] [varchar](100) NULL,
	[ApplicationURL] [varchar](200) NULL,
	[ApplicationTypeID] [int] NULL,
	[IsVisibleInsideGGP] [bit] NULL,
	[VProcessDependent] [bit] NULL,
	[CertificateExpiration] [datetime] NULL,
	[SMTP] [varchar](255) NULL,
	[IsVisibleNonEmployee] [bit] NULL,
	[FirewallException] [varchar](255) NULL,
	[LDAP] [varchar](255) NULL,
	[LastUpdatedBy] [varchar](100) NULL,
	[LastUpdated] [datetime] NULL,
	[SupportGroup] [int] NULL,
	[ApplicationLocationURL] [varchar](200) NULL,
	[Application_server] [int] NULL,
	[Application_database] [int] NULL,
 CONSTRAINT [PK_Application] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ApplicationADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationADGroup](
	[ApplicationADGroupID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[ADGroupID] [int] NOT NULL,
 CONSTRAINT [PK_ApplicationADGroup] PRIMARY KEY CLUSTERED 
(
	[ApplicationADGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationContact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationContact](
	[ApplicationContactID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[ContactID] [int] NOT NULL,
 CONSTRAINT [PK_ApplicationContact] PRIMARY KEY CLUSTERED 
(
	[ApplicationContactID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationDatabase](
	[ApplicationDatabaseID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[DatabaseID] [int] NOT NULL,
 CONSTRAINT [PK_ApplicationDatabase] PRIMARY KEY CLUSTERED 
(
	[ApplicationDatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationDocument](
	[ApplicationDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[DocumentID] [int] NOT NULL,
 CONSTRAINT [PK_ApplicationDocument] PRIMARY KEY CLUSTERED 
(
	[ApplicationDocumentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationLog]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ApplicationLog](
	[ApplicationLogId] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](150) NULL,
	[PrimaryKeyId] [int] NULL,
	[TransactionTime] [datetime] NULL,
	[UserName] [varchar](50) NULL,
	[LogText] [varchar](500) NULL,
 CONSTRAINT [PK_tblMemberAudit] PRIMARY KEY CLUSTERED 
(
	[ApplicationLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Applications]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Applications](
	[ApplicationID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Version] [varchar](25) NULL,
	[InstallerNames] [varchar](250) NULL,
	[DateInstalled] [datetime] NULL,
	[User] [varchar](100) NULL,
	[User2] [varchar](100) NULL,
	[UserContactInfo] [varchar](200) NULL,
	[User2ContactInfo] [varchar](200) NULL,
	[VendorName] [varchar](75) NULL,
	[VendorContact] [varchar](75) NULL,
	[VendorContactInfo] [varchar](200) NULL,
	[SupportContact] [varchar](75) NULL,
	[SupportContactInfo] [varchar](75) NULL,
	[SupportContactExpirationDate] [datetime] NULL,
	[NotesComments] [varchar](2000) NULL,
 CONSTRAINT [PK_Applications] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AppRecover]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AppRecover](
	[ApplicationID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Version] [varchar](25) NULL,
	[InstallerNames] [varchar](250) NULL,
	[DateInstalled] [datetime] NULL,
	[User] [varchar](100) NULL,
	[User2] [varchar](100) NULL,
	[UserContactInfo] [varchar](200) NULL,
	[User2ContactInfo] [varchar](200) NULL,
	[VendorName] [varchar](75) NULL,
	[VendorContact] [varchar](75) NULL,
	[VendorContactInfo] [varchar](200) NULL,
	[SupportContact] [varchar](75) NULL,
	[SupportContactInfo] [varchar](75) NULL,
	[SupportContactExpirationDate] [datetime] NULL,
	[NotesComments] [varchar](2000) NULL,
 CONSTRAINT [PK_AppRecover] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AspNetCompany]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AspNetCompany](
	[CompanyId] [int] IDENTITY(1,1) NOT NULL,
	[CompanyName] [varchar](500) NULL,
	[AllowedModules] [varchar](150) NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_aspNetCompany] PRIMARY KEY CLUSTERED 
(
	[CompanyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AspNetRoleClaims]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetRoleClaims](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClaimType] [nvarchar](max) NULL,
	[ClaimValue] [nvarchar](max) NULL,
	[RoleId] [nvarchar](450) NOT NULL,
 CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetRoles]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetRoles](
	[Id] [nvarchar](450) NOT NULL,
	[ConcurrencyStamp] [nvarchar](max) NULL,
	[Name] [nvarchar](256) NULL,
	[NormalizedName] [nvarchar](256) NULL,
 CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserClaims]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserClaims](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClaimType] [nvarchar](max) NULL,
	[ClaimValue] [nvarchar](max) NULL,
	[UserId] [nvarchar](450) NOT NULL,
 CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserLogins]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserLogins](
	[LoginProvider] [nvarchar](450) NOT NULL,
	[ProviderKey] [nvarchar](450) NOT NULL,
	[ProviderDisplayName] [nvarchar](max) NULL,
	[UserId] [nvarchar](450) NOT NULL,
 CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY CLUSTERED 
(
	[LoginProvider] ASC,
	[ProviderKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserRoles]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserRoles](
	[UserId] [nvarchar](450) NOT NULL,
	[RoleId] [nvarchar](450) NOT NULL,
 CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUsers]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUsers](
	[Id] [nvarchar](450) NOT NULL,
	[AccessFailedCount] [int] NOT NULL,
	[ConcurrencyStamp] [nvarchar](max) NULL,
	[Email] [nvarchar](256) NULL,
	[EmailConfirmed] [bit] NOT NULL,
	[LockoutEnabled] [bit] NOT NULL,
	[LockoutEnd] [datetimeoffset](7) NULL,
	[NormalizedEmail] [nvarchar](256) NULL,
	[NormalizedUserName] [nvarchar](256) NULL,
	[PasswordHash] [nvarchar](max) NULL,
	[PhoneNumber] [nvarchar](max) NULL,
	[PhoneNumberConfirmed] [bit] NOT NULL,
	[SecurityStamp] [nvarchar](max) NULL,
	[TwoFactorEnabled] [bit] NOT NULL,
	[UserName] [nvarchar](256) NULL,
	[CompanyId] [int] NULL,
	[CompanyName] [nvarchar](max) NULL,
 CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserTokens]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserTokens](
	[UserId] [nvarchar](450) NOT NULL,
	[LoginProvider] [nvarchar](450) NOT NULL,
	[Name] [nvarchar](450) NOT NULL,
	[Value] [nvarchar](max) NULL,
 CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[LoginProvider] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Authorization_AllowedCities]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authorization_AllowedCities](
	[AllowedCitiesId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NULL,
	[CityId] [int] NULL,
 CONSTRAINT [PK_Authorization_AllowedCities] PRIMARY KEY CLUSTERED 
(
	[AllowedCitiesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Authorization_AllowedCountries]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authorization_AllowedCountries](
	[AllowedCountriesId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NULL,
	[CountryId] [int] NULL,
 CONSTRAINT [PK_Authorization_AllowedCountries] PRIMARY KEY CLUSTERED 
(
	[AllowedCountriesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Authorization_AllowedDatacenters]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authorization_AllowedDatacenters](
	[AllowedDatacentersId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NULL,
	[DatacenterId] [int] NULL,
 CONSTRAINT [PK_Authorization_AllowedDatacenters] PRIMARY KEY CLUSTERED 
(
	[AllowedDatacentersId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Authorization_AllowedDepartments]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authorization_AllowedDepartments](
	[AllowedDepartmentsId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NULL,
	[DepartmentId] [int] NULL,
 CONSTRAINT [PK_Authorization_AllowedDepartments] PRIMARY KEY CLUSTERED 
(
	[AllowedDepartmentsId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Authorization_AllowedStates]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authorization_AllowedStates](
	[AllowedStatesId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NULL,
	[StateId] [int] NULL,
 CONSTRAINT [PK_Authorization_AllowedStates] PRIMARY KEY CLUSTERED 
(
	[AllowedStatesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Comment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Comment](
	[CommentID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NOT NULL,
	[ParentType] [varchar](10) NOT NULL,
	[DateEntered] [datetime] NOT NULL,
	[EnteredBy] [varchar](100) NOT NULL,
	[Comment] [text] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Community]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Community](
	[CommunityID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[CommunityAdminID] [varchar](50) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[Description] [varchar](500) NULL,
	[URL] [varchar](500) NULL,
	[CommunityTypeID] [int] NOT NULL,
	[LastUpdatedBy] [varchar](100) NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
	[isVisibleInsideGGP] [bit] NULL,
 CONSTRAINT [PK_Community] PRIMARY KEY CLUSTERED 
(
	[CommunityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CommunityADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommunityADGroup](
	[CommunityADID] [int] IDENTITY(1,1) NOT NULL,
	[CommunityID] [int] NOT NULL,
	[RoleID] [int] NULL,
	[ADGroupID] [int] NOT NULL,
 CONSTRAINT [PK_CommunityADGroup] PRIMARY KEY CLUSTERED 
(
	[CommunityADID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CommunityDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommunityDocument](
	[CommunityDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[CommunityID] [int] NOT NULL,
	[DocumentID] [int] NOT NULL,
 CONSTRAINT [PK_CommunityDocument] PRIMARY KEY CLUSTERED 
(
	[CommunityDocumentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[communityImport]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[communityImport](
	[Name] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[URL] [nvarchar](255) NULL,
	[adgroups] [nvarchar](1000) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Contact]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Contact](
	[ContactID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[MiddleInitial] [varchar](50) NULL,
	[Email] [varchar](100) NULL,
	[Phone] [varchar](100) NULL,
	[Title] [varchar](100) NULL,
	[LoginName] [varchar](50) NULL,
	[SID] [varchar](50) NULL,
	[EmployeeNo] [varchar](50) NULL,
	[IsValid] [bit] NULL,
	[ContactTypeID] [int] NULL,
	[ApplicationID] [int] NULL,
 CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED 
(
	[ContactID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DatabaseDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DatabaseDocument](
	[DatabaseDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseID] [int] NOT NULL,
	[DocumentID] [int] NOT NULL,
 CONSTRAINT [PK_DatabaseDocument] PRIMARY KEY CLUSTERED 
(
	[DatabaseDocumentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Databases]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Databases](
	[DatabaseID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NULL,
	[DBTypeID] [int] NULL,
	[DBVersion] [varchar](50) NULL,
	[InstallerNameID] [int] NULL,
	[InstalledDate] [datetime] NULL,
	[ServicePack] [varchar](50) NULL,
	[DbaID] [int] NULL,
	[IsDevDB] [bit] NULL,
	[IsTestDB] [bit] NULL,
	[IsProdDB] [bit] NULL,
	[Comments] [varchar](1000) NULL,
	[LastUpdatedBy] [varchar](100) NULL,
	[LastUpdated] [datetime] NULL,
	[DBTechnology] [varchar](50) NULL,
 CONSTRAINT [PK_Database] PRIMARY KEY CLUSTERED 
(
	[DatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Desktop]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Desktop](
	[DesktopID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[DesktopAdminID] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[Description] [varchar](500) NULL,
	[URL] [varchar](500) NULL,
	[LastUpdatedBy] [varchar](100) NOT NULL,
	[LastUpdated] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DesktopADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DesktopADGroup](
	[DesktopADID] [int] IDENTITY(1,1) NOT NULL,
	[DesktopID] [int] NOT NULL,
	[RoleID] [int] NULL,
	[ADGroupID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DesktopDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DesktopDocument](
	[DesktopDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[DesktopID] [int] NOT NULL,
	[DocumentID] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Document]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Document](
	[DocumentID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](255) NOT NULL,
	[Path] [varchar](500) NOT NULL,
 CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED 
(
	[DocumentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[framework_applicationlocation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[framework_applicationlocation](
	[Framework_applicationlocationID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NULL,
	[CityId] [int] NULL,
	[CountryId] [int] NULL,
	[StateId] [int] NULL,
	[DepartmentId] [int] NULL,
	[DataCenterId] [int] NULL,
 CONSTRAINT [PK_framework_applicationlocation] PRIMARY KEY CLUSTERED 
(
	[Framework_applicationlocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Framework_Databases_Location]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Framework_Databases_Location](
	[Framework_Database_LocationID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseID] [int] NULL,
	[CityId] [int] NULL,
	[CountryId] [int] NULL,
	[StateId] [int] NULL,
	[DepartmentId] [int] NULL,
	[DataCenterId] [int] NULL,
 CONSTRAINT [PK_Framework_Database_Location] PRIMARY KEY CLUSTERED 
(
	[Framework_Database_LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Framework_Server_Location]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Framework_Server_Location](
	[Framework_Server_LocationID] [int] IDENTITY(1,1) NOT NULL,
	[ServerID] [int] NOT NULL,
	[CityId] [int] NULL,
	[CountryId] [int] NULL,
	[StateId] [int] NULL,
	[DepartmentId] [int] NULL,
	[DataCenterId] [int] NULL,
 CONSTRAINT [PK_Framework_Server_Location] PRIMARY KEY CLUSTERED 
(
	[Framework_Server_LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GGPDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GGPDeveloper](
	[GGPDeveloperID] [int] IDENTITY(1,1) NOT NULL,
	[LeadDeveloper] [varchar](200) NULL,
	[BusinessAnalyst] [varchar](200) NULL,
	[ProgrammingLanguageID] [int] NULL,
 CONSTRAINT [PK_GGPDeveloper] PRIMARY KEY CLUSTERED 
(
	[GGPDeveloperID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ImportData]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ImportData](
	[Name] [nvarchar](255) NULL,
	[Version] [nvarchar](255) NULL,
	[Vendor Name] [nvarchar](255) NULL,
	[Primary Department] [nvarchar](255) NULL,
	[Long Description] [nvarchar](1000) NULL,
	[3rd Party or GGP Developed] [nvarchar](255) NULL,
	[Approximate # of Users] [float] NULL,
	[Technical Support] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Installation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Installation](
	[InstallationID] [int] IDENTITY(1,1) NOT NULL,
	[ServerID] [int] NOT NULL,
	[ApplicationID] [int] NOT NULL,
 CONSTRAINT [PK_Installation] PRIMARY KEY CLUSTERED 
(
	[InstallationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[lkpAdminEngineer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAdminEngineer](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpAdminEngineer] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpAllCities]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAllCities](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](50) NOT NULL,
	[StateName] [varchar](50) NOT NULL,
	[Latitude] [varchar](50) NOT NULL,
	[Longitude] [varchar](50) NOT NULL,
	[CountryName] [varchar](50) NULL,
 CONSTRAINT [PK_lkpCity] PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpAllCountries]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAllCountries](
	[CountryCode] [varchar](10) NOT NULL,
	[latitude] [varchar](50) NULL,
	[longitude] [varchar](50) NULL,
	[CountryName] [varchar](250) NULL,
	[MapId] [int] NULL,
 CONSTRAINT [PK_lkpAllCountries] PRIMARY KEY CLUSTERED 
(
	[CountryCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpAllStates]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAllStates](
	[StateName] [varchar](50) NOT NULL,
	[CountryCode] [varchar](50) NULL,
	[Latitude] [varchar](50) NOT NULL,
	[Longitude] [varchar](50) NOT NULL,
	[StateId] [varchar](50) NOT NULL,
 CONSTRAINT [PK_lkpAllStates] PRIMARY KEY CLUSTERED 
(
	[StateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpAntiVirus]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAntiVirus](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpAntiVirus] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpApplication](
	[ApplicationId] [int] NOT NULL,
	[ApplicationName] [varchar](50) NULL,
	[DepartmentId] [int] NULL,
	[ComapnyId] [varchar](50) NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_ApplicationId] PRIMARY KEY CLUSTERED 
(
	[ApplicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpAppType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpAppType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpAppType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpBusinessAnalyst]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpBusinessAnalyst](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpBusinessAnalyst] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpCabinet]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpCabinet](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[LookupID] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpCity]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpCity](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](50) NULL,
	[StateId] [int] NULL,
	[Latitude] [varchar](50) NULL,
	[Longitude] [varchar](50) NULL,
	[CompanyId] [varchar](50) NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_CityId] PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpClusterType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpClusterType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpClusterType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpCommunityRole]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpCommunityRole](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpCommunityRole] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpCommunityType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpCommunityType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpCommunityType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpContactType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpContactType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpContactType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpCountry]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpCountry](
	[CountryId] [int] IDENTITY(1,1) NOT NULL,
	[CountryName] [varchar](250) NULL,
	[Latitude] [varchar](50) NULL,
	[Longitude] [varchar](50) NULL,
	[CompanyId] [int] NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_lkpCountry] PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpDatabaseType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpDatabaseType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpDatabaseType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpDataCenter]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpDataCenter](
	[DataCenterId] [int] IDENTITY(1,1) NOT NULL,
	[DataCenterName] [varchar](500) NULL,
	[CityId] [int] NULL,
	[CompanyId] [varchar](50) NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_DataCenterId] PRIMARY KEY CLUSTERED 
(
	[DataCenterId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpDBA]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpDBA](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpDBA] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpDepartment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpDepartment](
	[DepartmentId] [int] IDENTITY(1,1) NOT NULL,
	[DepartmentName] [varchar](150) NULL,
	[DataCenterId] [int] NULL,
	[CompanyId] [varchar](50) NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_DepartmentId] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpFibreBackup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpFibreBackup](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpFibreBackup] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpFibreSwitchName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpFibreSwitchName](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpFibreSwitchName] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpFibreSwitchPort]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpFibreSwitchPort](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpFibreSwitchPort] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpInstaller]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpInstaller](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpInstaller] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpITGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpITGroup](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpITGroup] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpLeadDev]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpLeadDev](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpLeadDev] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpLocation]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpLocation](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpLocation] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpLookupTable]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpLookupTable](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpLookupTable] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpNetworkType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpNetworkType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpNetworkType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpOSType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpOSType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpOSType] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpProgrammingLanguage]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpProgrammingLanguage](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lstProgrammingLanguage] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpSAN]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpSAN](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NULL,
	[Description] [varchar](100) NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpSANSwitchName]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpSANSwitchName](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NULL,
	[Description] [varchar](100) NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpSANSwitchPort]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpSANSwitchPort](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NULL,
	[Description] [varchar](100) NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpServerType]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpServerType](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpServer] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpServerUse]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpServerUse](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpState]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpState](
	[StateId] [int] IDENTITY(1,1) NOT NULL,
	[StateName] [varchar](50) NULL,
	[CountryId] [int] NULL,
	[Latitude] [varchar](50) NULL,
	[Longitude] [varchar](50) NULL,
	[CompanyId] [varchar](50) NULL,
	[Active] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[ModifiedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_lkpState] PRIMARY KEY CLUSTERED 
(
	[StateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpSupportGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpSupportGroup](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpTestTable]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpTestTable](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_cCounty] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpVHost]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpVHost](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](30) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpVHost] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[lkpWebServer]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkpWebServer](
	[LookupID] [int] IDENTITY(1,1) NOT NULL,
	[CodeValue] [varchar](36) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[InvalidDate] [datetime] NULL,
 CONSTRAINT [PK_lkpWebServer] PRIMARY KEY CLUSTERED 
(
	[LookupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OutsideDeveloper]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[OutsideDeveloper](
	[OutsideDeveloperID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyName] [varchar](100) NOT NULL,
	[ContactID] [int] NOT NULL,
 CONSTRAINT [PK_OutsideDeveloper] PRIMARY KEY CLUSTERED 
(
	[OutsideDeveloperID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PortalADGroup]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortalADGroup](
	[PortalADID] [int] IDENTITY(1,1) NOT NULL,
	[PortalSiteID] [int] NULL,
	[RoleID] [int] NULL,
	[ADGroupID] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PortalDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortalDocument](
	[PortalDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[PortalSiteID] [int] NULL,
	[DocumentID] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PortalSites]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PortalSites](
	[PortalSiteID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[PortalAdminID] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[Description] [varchar](500) NULL,
	[URL] [varchar](500) NULL,
	[LastUpdatedBy] [varchar](100) NOT NULL,
	[LastUpdated] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Server]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Server](
	[ServerID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](600) NULL,
	[LocationID] [int] NULL,
	[IPAddress] [varchar](600) NULL,
	[AdminEngineerID] [int] NULL,
	[OS] [int] NULL,
	[ProcessorNumber] [smallint] NULL,
	[CPUSpeed] [varchar](50) NULL,
	[ServerMemory] [varchar](50) NULL,
	[Comment] [text] NULL,
	[VHostName] [varchar](50) NULL,
	[VirtualHostType] [smallint] NULL,
	[BackupDescription] [varchar](500) NULL,
	[WebServerTypeID] [int] NULL,
	[ServerTypeID] [int] NULL,
	[AntiVirusTypeID] [int] NULL,
	[RebootSchedule] [varchar](500) NULL,
	[ControllerNumber] [int] NULL,
	[DiskCapacity] [varchar](50) NULL,
	[NetworkTypeID] [int] NULL,
	[ITGroupID] [int] NULL,
	[GroupDescription] [varchar](500) NULL,
	[CabinetNo] [varchar](600) NULL,
	[ChasisNo] [varchar](600) NULL,
	[ModelNo] [varchar](600) NULL,
	[BladeNo] [varchar](600) NULL,
	[Generation] [varchar](600) NULL,
	[SerialNo] [varchar](600) NULL,
	[ILODNSName] [varchar](600) NULL,
	[ILOIPAddress] [varchar](600) NULL,
	[IPAddress2] [varchar](600) NULL,
	[IPAddress3] [varchar](600) NULL,
	[BackUpPath] [varchar](500) NULL,
	[ILOLicense] [varchar](600) NULL,
	[LastUpdatedBy] [varchar](100) NULL,
	[LastUpdated] [datetime] NULL,
	[NIC1CableNo] [varchar](100) NULL,
	[NIC1BunbleNo] [varchar](100) NULL,
	[IPAddress4] [varchar](40) NULL,
	[SAN] [int] NULL,
	[SANSwitchName] [int] NULL,
	[SANSwitchPort] [int] NULL,
	[FibreBackup] [int] NULL,
	[FibreSwitchName] [int] NULL,
	[FibreSwitchPort] [int] NULL,
	[ClusterType] [int] NULL,
	[ClusterName] [varchar](50) NULL,
	[ClusterIP1] [varchar](50) NULL,
	[ClusterIP2] [varchar](50) NULL,
	[ManufacturerNumber] [varchar](600) NULL,
	[Manufacturer] [varchar](600) NULL,
	[WarrantyExpiration] [datetime] NULL,
	[NIC1Bundle] [varchar](600) NULL,
	[NIC2Bundle] [varchar](600) NULL,
	[NIC3Bundle] [varchar](600) NULL,
	[NIC4Bundle] [varchar](600) NULL,
	[NIC1Cable] [varchar](600) NULL,
	[NIC2Cable] [varchar](600) NULL,
	[NIC3Cable] [varchar](600) NULL,
	[NIC4Cable] [varchar](600) NULL,
	[ClusterSAN] [int] NULL,
	[LUNNumber] [varchar](50) NULL,
	[SMTP] [bit] NULL,
	[Description] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[Network] [nvarchar](255) NULL,
	[iLO_Connection] [nvarchar](255) NULL,
	[ILO_Password] [nvarchar](255) NULL,
	[IsBackup] [nvarchar](255) NULL,
	[IsVirtualize] [bit] NULL,
	[Extend_Warranty] [bit] NULL,
	[NIC1Interface] [varchar](600) NULL,
	[NIC2Interface] [varchar](600) NULL,
	[NIC3Interface] [varchar](600) NULL,
	[NIC4Interface] [varchar](600) NULL,
	[NIC1Subnet] [varchar](600) NULL,
	[NIC2Subnet] [varchar](600) NULL,
	[NIC3Subnet] [varchar](600) NULL,
	[NIC4Subnet] [varchar](600) NULL,
	[NIC1SwitchPortNum] [varchar](600) NULL,
	[NIC2SwitchPortNum] [varchar](600) NULL,
	[NIC3SwitchPortNum] [varchar](600) NULL,
	[NIC4SwitchPortNum] [varchar](600) NULL,
	[NIC1VLAN] [int] NULL,
	[NIC2VLAN] [int] NULL,
	[NIC3VLAN] [int] NULL,
	[NIC4VLAN] [int] NULL,
	[NIC1SwitchName] [int] NULL,
	[NIC2SwitchName] [int] NULL,
	[NIC3SwitchName] [int] NULL,
	[NIC4SwitchName] [int] NULL,
	[CPUType] [varchar](600) NULL,
	[DNSServer1] [varchar](600) NULL,
	[DNSServer2] [varchar](600) NULL,
	[PhysicalDiskSize] [varchar](600) NULL,
	[RaidType] [int] NULL,
	[PhysicalDisks] [int] NULL,
	[Partition1DriveName] [varchar](600) NULL,
	[Partition2DriveName] [varchar](600) NULL,
	[Partition3DriveName] [varchar](600) NULL,
	[Partition4DriveName] [varchar](600) NULL,
	[Partition5DriveName] [varchar](600) NULL,
	[Partition6DriveName] [varchar](600) NULL,
	[Partition7DriveName] [varchar](600) NULL,
	[Partition8DriveName] [varchar](600) NULL,
	[Partition9DriveName] [varchar](600) NULL,
	[Partition10DriveName] [varchar](600) NULL,
	[Partition1Size] [varchar](600) NULL,
	[Partition2Size] [varchar](600) NULL,
	[Partition3Size] [varchar](600) NULL,
	[Partition4Size] [varchar](600) NULL,
	[Partition5Size] [varchar](600) NULL,
	[Partition6Size] [varchar](600) NULL,
	[Partition7Size] [varchar](600) NULL,
	[Partition8Size] [varchar](600) NULL,
	[Partition9Size] [varchar](600) NULL,
	[Partition10Size] [varchar](600) NULL,
	[VPartition1DriveName] [varchar](600) NULL,
	[VPartition2DriveName] [varchar](600) NULL,
	[VPartition3DriveName] [varchar](600) NULL,
	[VPartition4DriveName] [varchar](600) NULL,
	[VPartition5DriveName] [varchar](600) NULL,
	[VPartition6DriveName] [varchar](600) NULL,
	[VPartition7DriveName] [varchar](600) NULL,
	[VPartition8DriveName] [varchar](600) NULL,
	[VPartition9DriveName] [varchar](600) NULL,
	[VPartition10DriveName] [varchar](600) NULL,
	[VPartition1Size] [varchar](600) NULL,
	[VPartition2Size] [varchar](600) NULL,
	[VPartition3Size] [varchar](600) NULL,
	[VPartition4Size] [varchar](600) NULL,
	[VPartition5Size] [varchar](600) NULL,
	[VPartition6Size] [varchar](600) NULL,
	[VPartition7Size] [varchar](600) NULL,
	[VPartition8Size] [varchar](600) NULL,
	[VPartition9Size] [varchar](600) NULL,
	[VPartition10Size] [varchar](600) NULL,
	[Ownership] [int] NULL,
	[NumPartitions] [int] NULL,
	[VNumPartitions] [int] NULL,
	[ILOPassword] [varchar](600) NULL,
	[ServerUseID] [int] NULL,
 CONSTRAINT [PK_Server] PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ServerDatabase]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServerDatabase](
	[ServerDatabaseID] [int] IDENTITY(1,1) NOT NULL,
	[ServerID] [int] NOT NULL,
	[DatabaseID] [int] NOT NULL,
 CONSTRAINT [PK_ServerDatabase] PRIMARY KEY CLUSTERED 
(
	[ServerDatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ServerDocument]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServerDocument](
	[ServerDocumentID] [int] IDENTITY(1,1) NOT NULL,
	[ServerID] [int] NOT NULL,
	[DocumentID] [int] NOT NULL,
 CONSTRAINT [PK_ServerDocument] PRIMARY KEY CLUSTERED 
(
	[ServerDocumentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[serverImport]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serverImport](
	[ID] [float] NULL,
	[Name] [nvarchar](255) NULL,
	[IP] [nvarchar](255) NULL,
	[Group] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[Network] [nvarchar](255) NULL,
	[iLO Connection] [nvarchar](255) NULL,
	[Cabinet #] [nvarchar](255) NULL,
	[NCI 1 Bundle #] [nvarchar](255) NULL,
	[NIC 1 Cable #] [nvarchar](255) NULL,
	[Chassis #] [nvarchar](255) NULL,
	[Blade #] [nvarchar](255) NULL,
	[Model #] [nvarchar](255) NULL,
	[Generation] [nvarchar](255) NULL,
	[Serial #] [nvarchar](255) NULL,
	[iLO IP Address] [nvarchar](255) NULL,
	[iLO DNS Name] [nvarchar](255) NULL,
	[iLO License] [nvarchar](255) NULL,
	[IP #2] [nvarchar](255) NULL,
	[IP #3] [nvarchar](255) NULL,
	[ILO Password] [nvarchar](255) NULL,
	[NIC 2 Bundle #] [nvarchar](255) NULL,
	[NIC 3 Bundle #] [nvarchar](255) NULL,
	[NIC 4 Bundle #] [nvarchar](255) NULL,
	[NIC 2 Cable #] [nvarchar](255) NULL,
	[NIC 3 Cable #] [nvarchar](255) NULL,
	[NIC 4 Cable #] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ServerTypes]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ServerTypes](
	[ServerTypeID] [int] NOT NULL,
	[ServerType] [varchar](20) NULL,
 CONSTRAINT [PK_ServerTypes] PRIMARY KEY CLUSTERED 
(
	[ServerTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblApps]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblApps](
	[WorkStart15] [varchar](254) NULL,
	[WorkName8] [varchar](254) NULL,
	[WorkName16] [varchar](254) NULL,
	[WorkLoc20] [varchar](254) NULL,
	[WorkIPAdd8] [varchar](254) NULL,
	[WorkHardSpecs9] [varchar](254) NULL,
	[WorkHardSpecs19] [varchar](254) NULL,
	[WebServStartup17] [varchar](254) NULL,
	[WebServShutdown19] [varchar](254) NULL,
	[WebServName6] [varchar](254) NULL,
	[WebServName13] [varchar](254) NULL,
	[WebServLoc8] [varchar](254) NULL,
	[WebServLoc] [varchar](254) NULL,
	[WebServIP6] [varchar](254) NULL,
	[WebServIP13] [varchar](254) NULL,
	[WebServHardSpecs8] [varchar](254) NULL,
	[WebServHardSpecs17] [varchar](254) NULL,
	[WebServAdmin9] [varchar](254) NULL,
	[WebServAdmin18] [varchar](254) NULL,
	[WebInstall18] [text] NULL,
	[WebDBMgmt3] [varchar](254) NULL,
	[WebDBA] [varchar](254) NULL,
	[WebBackup6] [varchar](254) NULL,
	[TestServStartup10] [varchar](254) NULL,
	[TestServSoftSpecs11] [varchar](254) NULL,
	[TestServSoftSpecs] [varchar](254) NULL,
	[TestServShutdown6] [varchar](254) NULL,
	[TestServName9] [varchar](254) NULL,
	[TestServName19] [varchar](254) NULL,
	[TestServLoc10] [varchar](254) NULL,
	[TestServIP19] [varchar](254) NULL,
	[TestInstall2] [text] NULL,
	[TestIIS15] [varchar](254) NULL,
	[TestDBMgmt10] [varchar](254) NULL,
	[TestDBA14] [varchar](254) NULL,
	[TestBackup14] [varchar](254) NULL,
	[TestBackup] [varchar](254) NULL,
	[ProdServStartup16] [varchar](254) NULL,
	[ProdServSoftSpecs20] [varchar](254) NULL,
	[ProdServName15] [varchar](254) NULL,
	[ProdServLoc11] [varchar](254) NULL,
	[ProdServAdmin10] [varchar](254) NULL,
	[ProdInstall7] [text] NULL,
	[ProdIIS8] [varchar](254) NULL,
	[ProdIIS10] [varchar](254) NULL,
	[ProdDBMgmt15] [varchar](254) NULL,
	[ProdBackup18] [varchar](254) NULL,
	[InstallInstruc20] [varchar](254) NULL,
	[DevServStartup20] [varchar](254) NULL,
	[DevServStartup] [varchar](254) NULL,
	[DevServSoftSpecs19] [varchar](254) NULL,
	[DevServShutdown5] [varchar](254) NULL,
	[DevServShutdown18] [varchar](254) NULL,
	[WorkStart16] [varchar](254) NULL,
	[WorkName9] [varchar](254) NULL,
	[WorkName17] [varchar](254) NULL,
	[WorkLoc10] [varchar](254) NULL,
	[WorkIPAdd9] [varchar](254) NULL,
	[WebServStartup18] [varchar](254) NULL,
	[WebServName7] [varchar](254) NULL,
	[WebServName14] [varchar](254) NULL,
	[WebServLoc9] [varchar](254) NULL,
	[WebServIP7] [varchar](254) NULL,
	[WebServIP14] [varchar](254) NULL,
	[WebServHardSpecs9] [varchar](254) NULL,
	[WebServHardSpecs18] [varchar](254) NULL,
	[WebServAdmin19] [varchar](254) NULL,
	[WebInstall19] [text] NULL,
	[WebDBMgmt4] [varchar](254) NULL,
	[WebBackup7] [varchar](254) NULL,
	[WebBackup20] [varchar](254) NULL,
	[TestServStartup11] [varchar](254) NULL,
	[TestServSoftSpecs12] [varchar](254) NULL,
	[TestServShutdown7] [varchar](254) NULL,
	[TestServLoc11] [varchar](254) NULL,
	[TestInstall3] [text] NULL,
	[TestIIS16] [varchar](254) NULL,
	[TestDBMgmt11] [varchar](254) NULL,
	[TestDBA15] [varchar](254) NULL,
	[TestBackup15] [varchar](254) NULL,
	[ProdServStartup17] [varchar](254) NULL,
	[ProdServSoftSpecs10] [varchar](254) NULL,
	[ProdServName16] [varchar](254) NULL,
	[ProdServLoc2] [varchar](254) NULL,
	[ProdServLoc12] [varchar](254) NULL,
	[ProdServAdmin11] [varchar](254) NULL,
	[ProdInstall8] [text] NULL,
	[ProdIIS9] [varchar](254) NULL,
	[ProdIIS11] [varchar](254) NULL,
	[ProdIIS] [varchar](254) NULL,
	[ProdDBMgmt16] [varchar](254) NULL,
	[ProdBackup19] [varchar](254) NULL,
	[ProdBackup] [varchar](254) NULL,
	[InstallInstruc10] [varchar](254) NULL,
	[HardwareOrdered] [varchar](254) NULL,
	[DevServStartup10] [varchar](254) NULL,
	[DevServSoftSpecs] [varchar](254) NULL,
	[DevServShutdown6] [varchar](254) NULL,
	[DevServShutdown19] [varchar](254) NULL,
	[WorkStart2] [varchar](254) NULL,
	[WorkStart17] [varchar](254) NULL,
	[WorkSoftSpecs20] [varchar](254) NULL,
	[WorkShut20] [varchar](254) NULL,
	[WorkShut2] [varchar](254) NULL,
	[WorkName18] [varchar](254) NULL,
	[WorkLoc11] [varchar](254) NULL,
	[WebServStartup2] [varchar](254) NULL,
	[WebServStartup19] [varchar](254) NULL,
	[WebServName8] [varchar](254) NULL,
	[WebServName15] [varchar](254) NULL,
	[WebServName] [varchar](254) NULL,
	[WebServLoc20] [varchar](254) NULL,
	[WebServIP8] [varchar](254) NULL,
	[WebServIP15] [varchar](254) NULL,
	[WebServIP] [varchar](254) NULL,
	[WebServHardSpecs19] [varchar](254) NULL,
	[WebServAdmin] [varchar](254) NULL,
	[WebDBMgmt5] [varchar](254) NULL,
	[WebBackup8] [varchar](254) NULL,
	[WebBackup10] [varchar](254) NULL,
	[TestServStartup12] [varchar](254) NULL,
	[TestServSoftSpecs2] [varchar](254) NULL,
	[TestServSoftSpecs13] [varchar](254) NULL,
	[TestServShutdown8] [varchar](254) NULL,
	[TestServShutdown20] [varchar](254) NULL,
	[TestServLoc12] [varchar](254) NULL,
	[TestInstall4] [text] NULL,
	[TestIIS17] [varchar](254) NULL,
	[TestDBMgmt12] [varchar](254) NULL,
	[TestDBA16] [varchar](254) NULL,
	[TestBackup16] [varchar](254) NULL,
	[ProdServStartup2] [varchar](254) NULL,
	[ProdServStartup18] [varchar](254) NULL,
	[ProdServSoftSpecs11] [varchar](254) NULL,
	[ProdServName17] [varchar](254) NULL,
	[ProdServLoc3] [varchar](254) NULL,
	[ProdServLoc13] [varchar](254) NULL,
	[ProdServAdmin12] [varchar](254) NULL,
	[ProdInstall9] [text] NULL,
	[ProdIIS12] [varchar](254) NULL,
	[ProdDBMgmt17] [varchar](254) NULL,
	[ProdDBA11] [varchar](254) NULL,
	[ProdDBA] [varchar](254) NULL,
	[InstallInstruc11] [varchar](254) NULL,
	[DevServStartup11] [varchar](254) NULL,
	[DevServShutdown7] [varchar](254) NULL,
	[WorkStart3] [varchar](254) NULL,
	[WorkStart18] [varchar](254) NULL,
	[WorkSoftSpecs10] [varchar](254) NULL,
	[WorkSoftSpecs] [varchar](254) NULL,
	[WorkShut3] [varchar](254) NULL,
	[WorkShut10] [varchar](254) NULL,
	[WorkName19] [varchar](254) NULL,
	[WorkLoc12] [varchar](254) NULL,
	[WorkLoc] [varchar](254) NULL,
	[WebServStartup3] [varchar](254) NULL,
	[WebServSoftSpecs20] [varchar](254) NULL,
	[WebServName9] [varchar](254) NULL,
	[WebServName16] [varchar](254) NULL,
	[WebServLoc10] [varchar](254) NULL,
	[WebServIP9] [varchar](254) NULL,
	[WebServIP16] [varchar](254) NULL,
	[WebInstall] [text] NULL,
	[WebDBMgmt6] [varchar](254) NULL,
	[WebBackup9] [varchar](254) NULL,
	[WebBackup11] [varchar](254) NULL,
	[TotProds] [float] NULL,
	[TestServStartup2] [varchar](254) NULL,
	[TestServStartup13] [varchar](254) NULL,
	[TestServSoftSpecs3] [varchar](254) NULL,
	[TestServSoftSpecs14] [varchar](254) NULL,
	[TestServShutdown9] [varchar](254) NULL,
	[TestServShutdown10] [varchar](254) NULL,
	[TestServLoc13] [varchar](254) NULL,
	[TestServIP2] [varchar](254) NULL,
	[TestServAdmin2] [varchar](254) NULL,
	[TestInstall5] [text] NULL,
	[TestIIS18] [varchar](254) NULL,
	[TestDBMgmt13] [varchar](254) NULL,
	[TestDBA17] [varchar](254) NULL,
	[TestBackup2] [varchar](254) NULL,
	[TestBackup17] [varchar](254) NULL,
	[ProdServStartup3] [varchar](254) NULL,
	[ProdServStartup19] [varchar](254) NULL,
	[ProdServSoftSpecs12] [varchar](254) NULL,
	[ProdServName18] [varchar](254) NULL,
	[ProdServLoc4] [varchar](254) NULL,
	[ProdServLoc14] [varchar](254) NULL,
	[ProdServIP20] [varchar](254) NULL,
	[ProdServAdmin13] [varchar](254) NULL,
	[ProdIIS13] [varchar](254) NULL,
	[ProdDBMgmt18] [varchar](254) NULL,
	[ProdDBA12] [varchar](254) NULL,
	[InstallInstruc12] [varchar](254) NULL,
	[InstallInstruc] [varchar](254) NULL,
	[HardOrderDate] [varchar](254) NULL,
	[DevServStartup12] [varchar](254) NULL,
	[DevServShutdown8] [varchar](254) NULL,
	[WorkStart4] [varchar](254) NULL,
	[WorkStart19] [varchar](254) NULL,
	[WorkStart] [varchar](254) NULL,
	[WorkSoftSpecs11] [varchar](254) NULL,
	[WorkShut4] [varchar](254) NULL,
	[WorkShut11] [varchar](254) NULL,
	[WorkLoc13] [varchar](254) NULL,
	[WebServStartup4] [varchar](254) NULL,
	[WebServStartup] [varchar](254) NULL,
	[WebServSoftSpecs10] [varchar](254) NULL,
	[WebServShutdown] [varchar](254) NULL,
	[WebServName17] [varchar](254) NULL,
	[WebServLoc11] [varchar](254) NULL,
	[WebServIP17] [varchar](254) NULL,
	[WebServHardSpecs] [varchar](254) NULL,
	[WebIIS20] [varchar](254) NULL,
	[WebDBMgmt7] [varchar](254) NULL,
	[WebBackup12] [varchar](254) NULL,
	[TestServStartup3] [varchar](254) NULL,
	[TestServStartup14] [varchar](254) NULL,
	[TestServSoftSpecs4] [varchar](254) NULL,
	[TestServSoftSpecs15] [varchar](254) NULL,
	[TestServShutdown11] [varchar](254) NULL,
	[TestServLoc14] [varchar](254) NULL,
	[TestServIP3] [varchar](254) NULL,
	[TestServHardSpecs20] [varchar](254) NULL,
	[TestServAdmin3] [varchar](254) NULL,
	[TestServAdmin20] [varchar](254) NULL,
	[TestInstall6] [text] NULL,
	[TestIIS19] [varchar](254) NULL,
	[TestDBMgmt14] [varchar](254) NULL,
	[TestDBA2] [varchar](254) NULL,
	[TestDBA18] [varchar](254) NULL,
	[TestBackup3] [varchar](254) NULL,
	[TestBackup18] [varchar](254) NULL,
	[ProdServStartup4] [varchar](254) NULL,
	[ProdServSoftSpecs13] [varchar](254) NULL,
	[ProdServShutdown] [varchar](254) NULL,
	[ProdServName19] [varchar](254) NULL,
	[ProdServLoc5] [varchar](254) NULL,
	[ProdServLoc15] [varchar](254) NULL,
	[ProdServIP10] [varchar](254) NULL,
	[ProdServAdmin14] [varchar](254) NULL,
	[ProdInstall20] [text] NULL,
	[ProdIIS14] [varchar](254) NULL,
	[ProdDBMgmt19] [varchar](254) NULL,
	[ProdDBA13] [varchar](254) NULL,
	[InstallInstruc13] [varchar](254) NULL,
	[DevServStartup13] [varchar](254) NULL,
	[DevServShutdown9] [varchar](254) NULL,
	[WorkStart5] [varchar](254) NULL,
	[WorkSoftSpecs12] [varchar](254) NULL,
	[WorkShut5] [varchar](254) NULL,
	[WorkShut12] [varchar](254) NULL,
	[WorkLoc14] [varchar](254) NULL,
	[WebServStartup5] [varchar](254) NULL,
	[WebServSoftSpecs11] [varchar](254) NULL,
	[WebServName18] [varchar](254) NULL,
	[WebServLoc12] [varchar](254) NULL,
	[WebServIP18] [varchar](254) NULL,
	[WebInstall2] [text] NULL,
	[WebIIS10] [varchar](254) NULL,
	[WebDBMgmt8] [varchar](254) NULL,
	[WebDBMgmt20] [varchar](254) NULL,
	[WebDBMgmt] [varchar](254) NULL,
	[WebDBA20] [varchar](254) NULL,
	[WebBackup13] [varchar](254) NULL,
	[UNID] [varchar](34) NULL,
	[TestServStartup4] [varchar](254) NULL,
	[TestServStartup15] [varchar](254) NULL,
	[TestServSoftSpecs5] [varchar](254) NULL,
	[TestServSoftSpecs16] [varchar](254) NULL,
	[TestServShutdown12] [varchar](254) NULL,
	[TestServLoc2] [varchar](254) NULL,
	[TestServLoc15] [varchar](254) NULL,
	[TestServIP4] [varchar](254) NULL,
	[TestServHardSpecs10] [varchar](254) NULL,
	[TestServAdmin4] [varchar](254) NULL,
	[TestServAdmin10] [varchar](254) NULL,
	[TestInstall7] [text] NULL,
	[TestInstall20] [text] NULL,
	[TestIIS2] [varchar](254) NULL,
	[TestIIS] [varchar](254) NULL,
	[TestDBMgmt15] [varchar](254) NULL,
	[TestDBA3] [varchar](254) NULL,
	[TestDBA19] [varchar](254) NULL,
	[TestBackup4] [varchar](254) NULL,
	[TestBackup19] [varchar](254) NULL,
	[ProdServStartup5] [varchar](254) NULL,
	[ProdServSoftSpecs2] [varchar](254) NULL,
	[ProdServSoftSpecs14] [varchar](254) NULL,
	[ProdServShutdown20] [varchar](254) NULL,
	[ProdServLoc6] [varchar](254) NULL,
	[ProdServLoc16] [varchar](254) NULL,
	[ProdServIP11] [varchar](254) NULL,
	[ProdServHardSpecs20] [varchar](254) NULL,
	[ProdServHardSpecs] [varchar](254) NULL,
	[ProdServAdmin15] [varchar](254) NULL,
	[ProdInstall10] [text] NULL,
	[ProdIIS15] [varchar](254) NULL,
	[ProdDBA14] [varchar](254) NULL,
	[InstallInstruc14] [varchar](254) NULL,
	[DevServStartup14] [varchar](254) NULL,
	[AppName] [varchar](254) NULL,
	[WorkStart6] [varchar](254) NULL,
	[WorkSoftSpecs2] [varchar](254) NULL,
	[WorkSoftSpecs13] [varchar](254) NULL,
	[WorkShut6] [varchar](254) NULL,
	[WorkShut13] [varchar](254) NULL,
	[WorkLoc15] [varchar](254) NULL,
	[WorkIPAdd20] [varchar](254) NULL,
	[WebServStartup6] [varchar](254) NULL,
	[WebServSoftSpecs12] [varchar](254) NULL,
	[WebServShutdown2] [varchar](254) NULL,
	[WebServName19] [varchar](254) NULL,
	[WebServLoc13] [varchar](254) NULL,
	[WebServIP19] [varchar](254) NULL,
	[WebInstall3] [text] NULL,
	[WebIIS11] [varchar](254) NULL,
	[WebDBMgmt9] [varchar](254) NULL,
	[WebDBMgmt10] [varchar](254) NULL,
	[WebDBA2] [varchar](254) NULL,
	[WebDBA10] [varchar](254) NULL,
	[WebBackup14] [varchar](254) NULL,
	[TestServStartup5] [varchar](254) NULL,
	[TestServStartup16] [varchar](254) NULL,
	[TestServSoftSpecs6] [varchar](254) NULL,
	[TestServSoftSpecs17] [varchar](254) NULL,
	[TestServShutdown13] [varchar](254) NULL,
	[TestServShutdown] [varchar](254) NULL,
	[TestServLoc3] [varchar](254) NULL,
	[TestServLoc16] [varchar](254) NULL,
	[TestServIP5] [varchar](254) NULL,
	[TestServHardSpecs2] [varchar](254) NULL,
	[TestServHardSpecs11] [varchar](254) NULL,
	[TestServAdmin5] [varchar](254) NULL,
	[TestServAdmin11] [varchar](254) NULL,
	[TestInstall8] [text] NULL,
	[TestInstall10] [text] NULL,
	[TestIIS3] [varchar](254) NULL,
	[TestDBMgmt2] [varchar](254) NULL,
	[TestDBMgmt16] [varchar](254) NULL,
	[TestDBA4] [varchar](254) NULL,
	[TestDBA] [varchar](254) NULL,
	[TestBackup5] [varchar](254) NULL,
	[SoftRecDate] [varchar](254) NULL,
	[ProdServStartup6] [varchar](254) NULL,
	[ProdServSoftSpecs3] [varchar](254) NULL,
	[ProdServSoftSpecs15] [varchar](254) NULL,
	[ProdServShutdown10] [varchar](254) NULL,
	[ProdServLoc7] [varchar](254) NULL,
	[ProdServLoc17] [varchar](254) NULL,
	[ProdServIP2] [varchar](254) NULL,
	[ProdServIP12] [varchar](254) NULL,
	[ProdServHardSpecs10] [varchar](254) NULL,
	[ProdServAdmin16] [varchar](254) NULL,
	[ProdInstall11] [text] NULL,
	[ProdIIS16] [varchar](254) NULL,
	[ProdDBA15] [varchar](254) NULL,
	[ProdDB20] [varchar](254) NULL,
	[ProdBackup2] [varchar](254) NULL,
	[InstallInstruc2] [varchar](254) NULL,
	[InstallInstruc15] [varchar](254) NULL,
	[DevServStartup15] [varchar](254) NULL,
	[WorkStart7] [varchar](254) NULL,
	[WorkSoftSpecs3] [varchar](254) NULL,
	[WorkSoftSpecs14] [varchar](254) NULL,
	[WorkShut7] [varchar](254) NULL,
	[WorkShut14] [varchar](254) NULL,
	[WorkShut] [varchar](254) NULL,
	[WorkLoc2] [varchar](254) NULL,
	[WorkLoc16] [varchar](254) NULL,
	[WorkIPAdd10] [varchar](254) NULL,
	[WorkHardSpecs20] [varchar](254) NULL,
	[WebServStartup7] [varchar](254) NULL,
	[WebServSoftSpecs2] [varchar](254) NULL,
	[WebServSoftSpecs13] [varchar](254) NULL,
	[WebServShutdown3] [varchar](254) NULL,
	[WebServShutdown20] [varchar](254) NULL,
	[WebServLoc14] [varchar](254) NULL,
	[WebInstall4] [text] NULL,
	[WebIIS2] [varchar](254) NULL,
	[WebIIS12] [varchar](254) NULL,
	[WebDBMgmt11] [varchar](254) NULL,
	[WebDBA3] [varchar](254) NULL,
	[WebDBA11] [varchar](254) NULL,
	[WebBackup15] [varchar](254) NULL,
	[TestServStartup6] [varchar](254) NULL,
	[TestServStartup17] [varchar](254) NULL,
	[TestServSoftSpecs7] [varchar](254) NULL,
	[TestServSoftSpecs18] [varchar](254) NULL,
	[TestServShutdown14] [varchar](254) NULL,
	[TestServName20] [varchar](254) NULL,
	[TestServLoc4] [varchar](254) NULL,
	[TestServLoc17] [varchar](254) NULL,
	[TestServLoc] [varchar](254) NULL,
	[TestServIP6] [varchar](254) NULL,
	[TestServIP20] [varchar](254) NULL,
	[TestServHardSpecs3] [varchar](254) NULL,
	[TestServHardSpecs12] [varchar](254) NULL,
	[TestServAdmin6] [varchar](254) NULL,
	[TestServAdmin12] [varchar](254) NULL,
	[TestInstall9] [text] NULL,
	[TestInstall11] [text] NULL,
	[TestIIS4] [varchar](254) NULL,
	[TestDBMgmt3] [varchar](254) NULL,
	[TestDBMgmt17] [varchar](254) NULL,
	[TestDBA5] [varchar](254) NULL,
	[TestBackup6] [varchar](254) NULL,
	[SoftOrderDate] [varchar](254) NULL,
	[ProdServStartup7] [varchar](254) NULL,
	[ProdServSoftSpecs4] [varchar](254) NULL,
	[ProdServSoftSpecs16] [varchar](254) NULL,
	[ProdServShutdown2] [varchar](254) NULL,
	[ProdServShutdown11] [varchar](254) NULL,
	[ProdServLoc8] [varchar](254) NULL,
	[ProdServLoc18] [varchar](254) NULL,
	[ProdServIP3] [varchar](254) NULL,
	[ProdServIP13] [varchar](254) NULL,
	[ProdServHardSpecs11] [varchar](254) NULL,
	[ProdServAdmin2] [varchar](254) NULL,
	[ProdServAdmin17] [varchar](254) NULL,
	[ProdInstall12] [text] NULL,
	[ProdIIS17] [varchar](254) NULL,
	[ProdDBA16] [varchar](254) NULL,
	[ProdDB10] [varchar](254) NULL,
	[ProdBackup3] [varchar](254) NULL,
	[InstallInstruc3] [varchar](254) NULL,
	[InstallInstruc16] [varchar](254) NULL,
	[DevServStartup16] [varchar](254) NULL,
	[DevServSoftSpecs20] [varchar](254) NULL,
	[WorkStart8] [varchar](254) NULL,
	[WorkSoftSpecs4] [varchar](254) NULL,
	[WorkSoftSpecs15] [varchar](254) NULL,
	[WorkShut8] [varchar](254) NULL,
	[WorkShut15] [varchar](254) NULL,
	[WorkLoc3] [varchar](254) NULL,
	[WorkLoc17] [varchar](254) NULL,
	[WorkIPAdd11] [varchar](254) NULL,
	[WorkHardSpecs10] [varchar](254) NULL,
	[WebServStartup8] [varchar](254) NULL,
	[WebServSoftSpecs3] [varchar](254) NULL,
	[WebServSoftSpecs14] [varchar](254) NULL,
	[WebServShutdown4] [varchar](254) NULL,
	[WebServShutdown10] [varchar](254) NULL,
	[WebServLoc15] [varchar](254) NULL,
	[WebServAdmin20] [varchar](254) NULL,
	[WebInstall5] [text] NULL,
	[WebInstall20] [text] NULL,
	[WebIIS3] [varchar](254) NULL,
	[WebIIS13] [varchar](254) NULL,
	[WebDBMgmt12] [varchar](254) NULL,
	[WebDBA4] [varchar](254) NULL,
	[WebDBA12] [varchar](254) NULL,
	[WebBackup16] [varchar](254) NULL,
	[WebBackup] [varchar](254) NULL,
	[TestServStartup7] [varchar](254) NULL,
	[TestServStartup18] [varchar](254) NULL,
	[TestServSoftSpecs8] [varchar](254) NULL,
	[TestServSoftSpecs19] [varchar](254) NULL,
	[TestServShutdown15] [varchar](254) NULL,
	[TestServName10] [varchar](254) NULL,
	[TestServLoc5] [varchar](254) NULL,
	[TestServLoc18] [varchar](254) NULL,
	[TestServIP7] [varchar](254) NULL,
	[TestServIP10] [varchar](254) NULL,
	[TestServHardSpecs4] [varchar](254) NULL,
	[TestServHardSpecs13] [varchar](254) NULL,
	[TestServAdmin7] [varchar](254) NULL,
	[TestServAdmin13] [varchar](254) NULL,
	[TestInstall12] [text] NULL,
	[TestIIS5] [varchar](254) NULL,
	[TestDBMgmt4] [varchar](254) NULL,
	[TestDBMgmt18] [varchar](254) NULL,
	[TestDBA6] [varchar](254) NULL,
	[TestBackup7] [varchar](254) NULL,
	[ProdServStartup8] [varchar](254) NULL,
	[ProdServSoftSpecs5] [varchar](254) NULL,
	[ProdServSoftSpecs17] [varchar](254) NULL,
	[ProdServShutdown3] [varchar](254) NULL,
	[ProdServShutdown12] [varchar](254) NULL,
	[ProdServLoc9] [varchar](254) NULL,
	[ProdServLoc19] [varchar](254) NULL,
	[ProdServIP4] [varchar](254) NULL,
	[ProdServIP14] [varchar](254) NULL,
	[ProdServHardSpecs12] [varchar](254) NULL,
	[ProdServAdmin3] [varchar](254) NULL,
	[ProdServAdmin18] [varchar](254) NULL,
	[ProdInstall13] [text] NULL,
	[ProdIIS18] [varchar](254) NULL,
	[ProdDBA17] [varchar](254) NULL,
	[ProdBackup4] [varchar](254) NULL,
	[ProdBackup20] [varchar](254) NULL,
	[InstallInstruc4] [varchar](254) NULL,
	[InstallInstruc17] [varchar](254) NULL,
	[DevServStartup2] [varchar](254) NULL,
	[DevServStartup17] [varchar](254) NULL,
	[DevServSoftSpecs2] [varchar](254) NULL,
	[DevServSoftSpecs10] [varchar](254) NULL,
	[DevServShutdown20] [varchar](254) NULL,
	[WorkStart9] [varchar](254) NULL,
	[WorkSoftSpecs5] [varchar](254) NULL,
	[WorkSoftSpecs16] [varchar](254) NULL,
	[WorkShut9] [varchar](254) NULL,
	[WorkShut16] [varchar](254) NULL,
	[WorkLoc4] [varchar](254) NULL,
	[WorkLoc18] [varchar](254) NULL,
	[WorkIPAdd12] [varchar](254) NULL,
	[WorkHardSpecs11] [varchar](254) NULL,
	[WebServStartup9] [varchar](254) NULL,
	[WebServStartup20] [varchar](254) NULL,
	[WebServSoftSpecs4] [varchar](254) NULL,
	[WebServSoftSpecs15] [varchar](254) NULL,
	[WebServShutdown5] [varchar](254) NULL,
	[WebServShutdown11] [varchar](254) NULL,
	[WebServLoc16] [varchar](254) NULL,
	[WebServHardSpecs20] [varchar](254) NULL,
	[WebServAdmin10] [varchar](254) NULL,
	[WebInstall6] [text] NULL,
	[WebInstall10] [text] NULL,
	[WebIIS4] [varchar](254) NULL,
	[WebIIS14] [varchar](254) NULL,
	[WebDBMgmt13] [varchar](254) NULL,
	[WebDBA5] [varchar](254) NULL,
	[WebDBA13] [varchar](254) NULL,
	[WebBackup17] [varchar](254) NULL,
	[TotWorks] [float] NULL,
	[TestServStartup8] [varchar](254) NULL,
	[TestServStartup19] [varchar](254) NULL,
	[TestServSoftSpecs9] [varchar](254) NULL,
	[TestServShutdown16] [varchar](254) NULL,
	[TestServName11] [varchar](254) NULL,
	[TestServLoc6] [varchar](254) NULL,
	[TestServLoc19] [varchar](254) NULL,
	[TestServIP8] [varchar](254) NULL,
	[TestServIP11] [varchar](254) NULL,
	[TestServHardSpecs5] [varchar](254) NULL,
	[TestServHardSpecs14] [varchar](254) NULL,
	[TestServAdmin8] [varchar](254) NULL,
	[TestServAdmin14] [varchar](254) NULL,
	[TestInstall13] [text] NULL,
	[TestIIS6] [varchar](254) NULL,
	[TestDBMgmt5] [varchar](254) NULL,
	[TestDBMgmt19] [varchar](254) NULL,
	[TestDBA7] [varchar](254) NULL,
	[TestBackup8] [varchar](254) NULL,
	[ProdServStartup9] [varchar](254) NULL,
	[ProdServSoftSpecs6] [varchar](254) NULL,
	[ProdServSoftSpecs18] [varchar](254) NULL,
	[ProdServShutdown4] [varchar](254) NULL,
	[ProdServShutdown13] [varchar](254) NULL,
	[ProdServName2] [varchar](254) NULL,
	[ProdServName] [varchar](254) NULL,
	[ProdServIP5] [varchar](254) NULL,
	[ProdServIP15] [varchar](254) NULL,
	[ProdServHardSpecs2] [varchar](254) NULL,
	[ProdServHardSpecs13] [varchar](254) NULL,
	[ProdServAdmin4] [varchar](254) NULL,
	[ProdServAdmin19] [varchar](254) NULL,
	[ProdInstall14] [text] NULL,
	[ProdIIS19] [varchar](254) NULL,
	[ProdDBMgmt2] [varchar](254) NULL,
	[ProdDBA18] [varchar](254) NULL,
	[ProdBackup5] [varchar](254) NULL,
	[ProdBackup10] [varchar](254) NULL,
	[InstallInstruc5] [varchar](254) NULL,
	[InstallInstruc18] [varchar](254) NULL,
	[DevServStartup3] [varchar](254) NULL,
	[DevServStartup18] [varchar](254) NULL,
	[DevServSoftSpecs3] [varchar](254) NULL,
	[DevServSoftSpecs11] [varchar](254) NULL,
	[DevServShutdown10] [varchar](254) NULL,
	[WorkSoftSpecs6] [varchar](254) NULL,
	[WorkSoftSpecs17] [varchar](254) NULL,
	[WorkShut17] [varchar](254) NULL,
	[WorkName20] [varchar](254) NULL,
	[WorkLoc5] [varchar](254) NULL,
	[WorkLoc19] [varchar](254) NULL,
	[WorkIPAdd13] [varchar](254) NULL,
	[WorkHardSpecs2] [varchar](254) NULL,
	[WorkHardSpecs12] [varchar](254) NULL,
	[WebServStartup10] [varchar](254) NULL,
	[WebServSoftSpecs5] [varchar](254) NULL,
	[WebServSoftSpecs16] [varchar](254) NULL,
	[WebServSoftSpecs] [varchar](254) NULL,
	[WebServShutdown6] [varchar](254) NULL,
	[WebServShutdown12] [varchar](254) NULL,
	[WebServLoc17] [varchar](254) NULL,
	[WebServHardSpecs10] [varchar](254) NULL,
	[WebServAdmin2] [varchar](254) NULL,
	[WebServAdmin11] [varchar](254) NULL,
	[WebInstall7] [text] NULL,
	[WebInstall11] [text] NULL,
	[WebIIS5] [varchar](254) NULL,
	[WebIIS15] [varchar](254) NULL,
	[WebDBMgmt14] [varchar](254) NULL,
	[WebDBA6] [varchar](254) NULL,
	[WebDBA14] [varchar](254) NULL,
	[WebBackup18] [varchar](254) NULL,
	[TestServStartup9] [varchar](254) NULL,
	[TestServShutdown17] [varchar](254) NULL,
	[TestServName2] [varchar](254) NULL,
	[TestServName12] [varchar](254) NULL,
	[TestServLoc7] [varchar](254) NULL,
	[TestServIP9] [varchar](254) NULL,
	[TestServIP12] [varchar](254) NULL,
	[TestServHardSpecs6] [varchar](254) NULL,
	[TestServHardSpecs15] [varchar](254) NULL,
	[TestServAdmin9] [varchar](254) NULL,
	[TestServAdmin15] [varchar](254) NULL,
	[TestInstall14] [text] NULL,
	[TestInstall] [text] NULL,
	[TestIIS7] [varchar](254) NULL,
	[TestDBMgmt6] [varchar](254) NULL,
	[TestDBA8] [varchar](254) NULL,
	[TestBackup9] [varchar](254) NULL,
	[ProdServStartup20] [varchar](254) NULL,
	[ProdServSoftSpecs7] [varchar](254) NULL,
	[ProdServSoftSpecs19] [varchar](254) NULL,
	[ProdServShutdown5] [varchar](254) NULL,
	[ProdServShutdown14] [varchar](254) NULL,
	[ProdServName3] [varchar](254) NULL,
	[ProdServLoc] [varchar](254) NULL,
	[ProdServIP6] [varchar](254) NULL,
	[ProdServIP16] [varchar](254) NULL,
	[ProdServHardSpecs3] [varchar](254) NULL,
	[ProdServHardSpecs14] [varchar](254) NULL,
	[ProdServAdmin5] [varchar](254) NULL,
	[ProdInstall15] [text] NULL,
	[ProdDBMgmt3] [varchar](254) NULL,
	[ProdDBA2] [varchar](254) NULL,
	[ProdBackup6] [varchar](254) NULL,
	[ProdBackup11] [varchar](254) NULL,
	[InstallInstruc6] [varchar](254) NULL,
	[InstallInstruc19] [varchar](254) NULL,
	[DevServStartup4] [varchar](254) NULL,
	[DevServStartup19] [varchar](254) NULL,
	[DevServSoftSpecs4] [varchar](254) NULL,
	[DevServSoftSpecs12] [varchar](254) NULL,
	[DevServShutdown11] [varchar](254) NULL,
	[DevServShutdown] [varchar](254) NULL,
	[WorkStart20] [varchar](254) NULL,
	[WorkSoftSpecs7] [varchar](254) NULL,
	[WorkSoftSpecs18] [varchar](254) NULL,
	[WorkShut18] [varchar](254) NULL,
	[WorkName2] [varchar](254) NULL,
	[WorkName10] [varchar](254) NULL,
	[WorkLoc6] [varchar](254) NULL,
	[WorkIPAdd2] [varchar](254) NULL,
	[WorkIPAdd14] [varchar](254) NULL,
	[WorkHardSpecs3] [varchar](254) NULL,
	[WorkHardSpecs13] [varchar](254) NULL,
	[WebServStartup11] [varchar](254) NULL,
	[WebServSoftSpecs6] [varchar](254) NULL,
	[WebServSoftSpecs17] [varchar](254) NULL,
	[WebServShutdown7] [varchar](254) NULL,
	[WebServShutdown13] [varchar](254) NULL,
	[WebServLoc2] [varchar](254) NULL,
	[WebServLoc18] [varchar](254) NULL,
	[WebServHardSpecs2] [varchar](254) NULL,
	[WebServHardSpecs11] [varchar](254) NULL,
	[WebServAdmin3] [varchar](254) NULL,
	[WebServAdmin12] [varchar](254) NULL,
	[WebInstall8] [text] NULL,
	[WebInstall12] [text] NULL,
	[WebIIS6] [varchar](254) NULL,
	[WebIIS16] [varchar](254) NULL,
	[WebDBMgmt15] [varchar](254) NULL,
	[WebDBA7] [varchar](254) NULL,
	[WebDBA15] [varchar](254) NULL,
	[WebBackup19] [varchar](254) NULL,
	[TotDBs] [float] NULL,
	[TotApps] [float] NULL,
	[TestServShutdown18] [varchar](254) NULL,
	[TestServName3] [varchar](254) NULL,
	[TestServLoc8] [varchar](254) NULL,
	[TestServIP13] [varchar](254) NULL,
	[TestServIP] [varchar](254) NULL,
	[TestServHardSpecs7] [varchar](254) NULL,
	[TestServHardSpecs16] [varchar](254) NULL,
	[TestServAdmin16] [varchar](254) NULL,
	[TestInstall15] [text] NULL,
	[TestIIS8] [varchar](254) NULL,
	[TestIIS20] [varchar](254) NULL,
	[TestDBMgmt7] [varchar](254) NULL,
	[TestDBA9] [varchar](254) NULL,
	[SoftwareOrdered] [varchar](254) NULL,
	[ProdServStartup10] [varchar](254) NULL,
	[ProdServSoftSpecs8] [varchar](254) NULL,
	[ProdServSoftSpecs] [varchar](254) NULL,
	[ProdServShutdown6] [varchar](254) NULL,
	[ProdServShutdown15] [varchar](254) NULL,
	[ProdServName4] [varchar](254) NULL,
	[ProdServName20] [varchar](254) NULL,
	[ProdServIP7] [varchar](254) NULL,
	[ProdServIP17] [varchar](254) NULL,
	[ProdServHardSpecs4] [varchar](254) NULL,
	[ProdServHardSpecs15] [varchar](254) NULL,
	[ProdServAdmin6] [varchar](254) NULL,
	[ProdInstall16] [text] NULL,
	[ProdIIS2] [varchar](254) NULL,
	[ProdDBMgmt4] [varchar](254) NULL,
	[ProdDBMgmt20] [varchar](254) NULL,
	[ProdDBA3] [varchar](254) NULL,
	[ProdDB9] [varchar](254) NULL,
	[ProdBackup7] [varchar](254) NULL,
	[ProdBackup12] [varchar](254) NULL,
	[InstallInstruc7] [varchar](254) NULL,
	[DevServStartup5] [varchar](254) NULL,
	[DevServSoftSpecs5] [varchar](254) NULL,
	[DevServSoftSpecs13] [varchar](254) NULL,
	[DevServShutdown12] [varchar](254) NULL,
	[WorkStart10] [varchar](254) NULL,
	[WorkSoftSpecs8] [varchar](254) NULL,
	[WorkSoftSpecs19] [varchar](254) NULL,
	[WorkShut19] [varchar](254) NULL,
	[WorkName3] [varchar](254) NULL,
	[WorkName11] [varchar](254) NULL,
	[WorkLoc7] [varchar](254) NULL,
	[WorkIPAdd3] [varchar](254) NULL,
	[WorkIPAdd15] [varchar](254) NULL,
	[WorkHardSpecs4] [varchar](254) NULL,
	[WorkHardSpecs14] [varchar](254) NULL,
	[WebServStartup12] [varchar](254) NULL,
	[WebServSoftSpecs7] [varchar](254) NULL,
	[WebServSoftSpecs18] [varchar](254) NULL,
	[WebServShutdown8] [varchar](254) NULL,
	[WebServShutdown14] [varchar](254) NULL,
	[WebServLoc3] [varchar](254) NULL,
	[WebServLoc19] [varchar](254) NULL,
	[WebServHardSpecs3] [varchar](254) NULL,
	[WebServHardSpecs12] [varchar](254) NULL,
	[WebServAdmin4] [varchar](254) NULL,
	[WebServAdmin13] [varchar](254) NULL,
	[WebInstall9] [text] NULL,
	[WebInstall13] [text] NULL,
	[WebIIS7] [varchar](254) NULL,
	[WebIIS17] [varchar](254) NULL,
	[WebDBMgmt16] [varchar](254) NULL,
	[WebDBA8] [varchar](254) NULL,
	[WebDBA16] [varchar](254) NULL,
	[TotWeb] [float] NULL,
	[TestServShutdown19] [varchar](254) NULL,
	[TestServName4] [varchar](254) NULL,
	[TestServName14] [varchar](254) NULL,
	[TestServLoc9] [varchar](254) NULL,
	[TestServIP14] [varchar](254) NULL,
	[TestServHardSpecs8] [varchar](254) NULL,
	[TestServHardSpecs17] [varchar](254) NULL,
	[TestServHardSpecs] [varchar](254) NULL,
	[TestServAdmin17] [varchar](254) NULL,
	[TestInstall16] [text] NULL,
	[TestIIS9] [varchar](254) NULL,
	[TestIIS10] [varchar](254) NULL,
	[TestDBMgmt8] [varchar](254) NULL,
	[TestDBA20] [varchar](254) NULL,
	[TestBackup20] [varchar](254) NULL,
	[ServerType] [varchar](254) NULL,
	[ProdServStartup11] [varchar](254) NULL,
	[ProdServStartup] [varchar](254) NULL,
	[ProdServSoftSpecs9] [varchar](254) NULL,
	[ProdServShutdown7] [varchar](254) NULL,
	[ProdServShutdown16] [varchar](254) NULL,
	[ProdServName5] [varchar](254) NULL,
	[ProdServName10] [varchar](254) NULL,
	[ProdServIP8] [varchar](254) NULL,
	[ProdServIP18] [varchar](254) NULL,
	[ProdServHardSpecs5] [varchar](254) NULL,
	[ProdServHardSpecs16] [varchar](254) NULL,
	[ProdServAdmin7] [varchar](254) NULL,
	[ProdInstall2] [text] NULL,
	[ProdInstall17] [text] NULL,
	[ProdIIS3] [varchar](254) NULL,
	[ProdDBMgmt5] [varchar](254) NULL,
	[ProdDBMgmt10] [varchar](254) NULL,
	[ProdDBA4] [varchar](254) NULL,
	[ProdBackup8] [varchar](254) NULL,
	[ProdBackup13] [varchar](254) NULL,
	[InstallInstruc8] [varchar](254) NULL,
	[HardRecDate] [varchar](254) NULL,
	[DevServStartup6] [varchar](254) NULL,
	[DevServSoftSpecs6] [varchar](254) NULL,
	[DevServSoftSpecs14] [varchar](254) NULL,
	[DevServShutdown13] [varchar](254) NULL,
	[WorkStart11] [varchar](254) NULL,
	[WorkSoftSpecs9] [varchar](254) NULL,
	[WorkName4] [varchar](254) NULL,
	[WorkName12] [varchar](254) NULL,
	[WorkLoc8] [varchar](254) NULL,
	[WorkIPAdd4] [varchar](254) NULL,
	[WorkIPAdd16] [varchar](254) NULL,
	[WorkIPAdd] [varchar](254) NULL,
	[WorkHardSpecs5] [varchar](254) NULL,
	[WorkHardSpecs15] [varchar](254) NULL,
	[WebServStartup13] [varchar](254) NULL,
	[WebServSoftSpecs8] [varchar](254) NULL,
	[WebServSoftSpecs19] [varchar](254) NULL,
	[WebServShutdown9] [varchar](254) NULL,
	[WebServShutdown15] [varchar](254) NULL,
	[WebServName20] [varchar](254) NULL,
	[WebServName2] [varchar](254) NULL,
	[WebServLoc4] [varchar](254) NULL,
	[WebServIP20] [varchar](254) NULL,
	[WebServIP2] [varchar](254) NULL,
	[WebServHardSpecs4] [varchar](254) NULL,
	[WebServHardSpecs13] [varchar](254) NULL,
	[WebServAdmin5] [varchar](254) NULL,
	[WebServAdmin14] [varchar](254) NULL,
	[WebInstall14] [text] NULL,
	[WebIIS8] [varchar](254) NULL,
	[WebIIS18] [varchar](254) NULL,
	[WebDBMgmt17] [varchar](254) NULL,
	[WebDBA9] [varchar](254) NULL,
	[WebDBA17] [varchar](254) NULL,
	[WebBackup2] [varchar](254) NULL,
	[TotTest] [float] NULL,
	[TotDev] [float] NULL,
	[TestServShutdown2] [varchar](254) NULL,
	[TestServName5] [varchar](254) NULL,
	[TestServName15] [varchar](254) NULL,
	[TestServName] [varchar](254) NULL,
	[TestServIP15] [varchar](254) NULL,
	[TestServHardSpecs9] [varchar](254) NULL,
	[TestServHardSpecs18] [varchar](254) NULL,
	[TestServAdmin18] [varchar](254) NULL,
	[TestInstall17] [text] NULL,
	[TestIIS11] [varchar](254) NULL,
	[TestDBMgmt9] [varchar](254) NULL,
	[TestDBA10] [varchar](254) NULL,
	[TestBackup10] [varchar](254) NULL,
	[ProdServStartup12] [varchar](254) NULL,
	[ProdServShutdown8] [varchar](254) NULL,
	[ProdServShutdown17] [varchar](254) NULL,
	[ProdServName6] [varchar](254) NULL,
	[ProdServName11] [varchar](254) NULL,
	[ProdServIP9] [varchar](254) NULL,
	[ProdServIP19] [varchar](254) NULL,
	[ProdServIP] [varchar](254) NULL,
	[ProdServHardSpecs6] [varchar](254) NULL,
	[ProdServHardSpecs17] [varchar](254) NULL,
	[ProdServAdmin8] [varchar](254) NULL,
	[ProdInstall3] [text] NULL,
	[ProdInstall18] [text] NULL,
	[ProdInstall] [text] NULL,
	[ProdIIS4] [varchar](254) NULL,
	[ProdDBMgmt6] [varchar](254) NULL,
	[ProdDBMgmt11] [varchar](254) NULL,
	[ProdDBA5] [varchar](254) NULL,
	[ProdBackup9] [varchar](254) NULL,
	[ProdBackup14] [varchar](254) NULL,
	[InstallInstruc9] [varchar](254) NULL,
	[DevServStartup7] [varchar](254) NULL,
	[DevServSoftSpecs7] [varchar](254) NULL,
	[DevServSoftSpecs15] [varchar](254) NULL,
	[DevServShutdown14] [varchar](254) NULL,
	[WorkStart12] [varchar](254) NULL,
	[WorkName5] [varchar](254) NULL,
	[WorkName13] [varchar](254) NULL,
	[WorkLoc9] [varchar](254) NULL,
	[WorkIPAdd5] [varchar](254) NULL,
	[WorkIPAdd17] [varchar](254) NULL,
	[WorkHardSpecs6] [varchar](254) NULL,
	[WorkHardSpecs16] [varchar](254) NULL,
	[WebServStartup14] [varchar](254) NULL,
	[WebServSoftSpecs9] [varchar](254) NULL,
	[WebServShutdown16] [varchar](254) NULL,
	[WebServName3] [varchar](254) NULL,
	[WebServName10] [varchar](254) NULL,
	[WebServLoc5] [varchar](254) NULL,
	[WebServIP3] [varchar](254) NULL,
	[WebServIP10] [varchar](254) NULL,
	[WebServHardSpecs5] [varchar](254) NULL,
	[WebServHardSpecs14] [varchar](254) NULL,
	[WebServAdmin6] [varchar](254) NULL,
	[WebServAdmin15] [varchar](254) NULL,
	[WebInstall15] [text] NULL,
	[WebIIS9] [varchar](254) NULL,
	[WebIIS19] [varchar](254) NULL,
	[WebDBMgmt18] [varchar](254) NULL,
	[WebDBA18] [varchar](254) NULL,
	[WebBackup3] [varchar](254) NULL,
	[TestServShutdown3] [varchar](254) NULL,
	[TestServName6] [varchar](254) NULL,
	[TestServName16] [varchar](254) NULL,
	[TestServIP16] [varchar](254) NULL,
	[TestServHardSpecs19] [varchar](254) NULL,
	[TestServAdmin19] [varchar](254) NULL,
	[TestInstall18] [text] NULL,
	[TestIIS12] [varchar](254) NULL,
	[TestDBMgmt] [varchar](254) NULL,
	[TestDBA11] [varchar](254) NULL,
	[TestBackup11] [varchar](254) NULL,
	[ProdServStartup13] [varchar](254) NULL,
	[ProdServShutdown9] [varchar](254) NULL,
	[ProdServShutdown18] [varchar](254) NULL,
	[ProdServName7] [varchar](254) NULL,
	[ProdServName12] [varchar](254) NULL,
	[ProdServHardSpecs7] [varchar](254) NULL,
	[ProdServHardSpecs18] [varchar](254) NULL,
	[ProdServAdmin9] [varchar](254) NULL,
	[ProdInstall4] [text] NULL,
	[ProdInstall19] [text] NULL,
	[ProdIIS5] [varchar](254) NULL,
	[ProdDBMgmt7] [varchar](254) NULL,
	[ProdDBMgmt12] [varchar](254) NULL,
	[ProdDBA6] [varchar](254) NULL,
	[ProdBackup15] [varchar](254) NULL,
	[HardInvComp] [varchar](254) NULL,
	[DevServStartup8] [varchar](254) NULL,
	[DevServSoftSpecs8] [varchar](254) NULL,
	[DevServSoftSpecs16] [varchar](254) NULL,
	[DevServShutdown2] [varchar](254) NULL,
	[DevServShutdown15] [varchar](254) NULL,
	[WorkStart13] [varchar](254) NULL,
	[WorkName6] [varchar](254) NULL,
	[WorkName14] [varchar](254) NULL,
	[WorkName] [varchar](254) NULL,
	[WorkIPAdd6] [varchar](254) NULL,
	[WorkIPAdd18] [varchar](254) NULL,
	[WorkHardSpecs7] [varchar](254) NULL,
	[WorkHardSpecs17] [varchar](254) NULL,
	[WorkHardSpecs] [varchar](254) NULL,
	[WebServStartup15] [varchar](254) NULL,
	[WebServShutdown17] [varchar](254) NULL,
	[WebServName4] [varchar](254) NULL,
	[WebServName11] [varchar](254) NULL,
	[WebServLoc6] [varchar](254) NULL,
	[WebServIP4] [varchar](254) NULL,
	[WebServIP11] [varchar](254) NULL,
	[WebServHardSpecs6] [varchar](254) NULL,
	[WebServHardSpecs15] [varchar](254) NULL,
	[WebServAdmin7] [varchar](254) NULL,
	[WebServAdmin16] [varchar](254) NULL,
	[WebInstall16] [text] NULL,
	[WebDBMgmt19] [varchar](254) NULL,
	[WebDBA19] [varchar](254) NULL,
	[WebBackup4] [varchar](254) NULL,
	[TestServSoftSpecs20] [varchar](254) NULL,
	[TestServShutdown4] [varchar](254) NULL,
	[TestServName7] [varchar](254) NULL,
	[TestServName17] [varchar](254) NULL,
	[TestServIP17] [varchar](254) NULL,
	[TestInstall19] [text] NULL,
	[TestIIS13] [varchar](254) NULL,
	[TestDBA12] [varchar](254) NULL,
	[TestBackup12] [varchar](254) NULL,
	[ProdServStartup14] [varchar](254) NULL,
	[ProdServShutdown19] [varchar](254) NULL,
	[ProdServName8] [varchar](254) NULL,
	[ProdServName13] [varchar](254) NULL,
	[ProdServLoc20] [varchar](254) NULL,
	[ProdServHardSpecs8] [varchar](254) NULL,
	[ProdServHardSpecs19] [varchar](254) NULL,
	[ProdServAdmin] [varchar](254) NULL,
	[ProdInstall5] [text] NULL,
	[ProdIIS6] [varchar](254) NULL,
	[ProdDBMgmt8] [varchar](254) NULL,
	[ProdDBMgmt13] [varchar](254) NULL,
	[ProdDBMgmt] [varchar](254) NULL,
	[ProdDBA7] [varchar](254) NULL,
	[ProdBackup16] [varchar](254) NULL,
	[DevServStartup9] [varchar](254) NULL,
	[DevServSoftSpecs9] [varchar](254) NULL,
	[DevServSoftSpecs17] [varchar](254) NULL,
	[DevServShutdown3] [varchar](254) NULL,
	[DevServShutdown16] [varchar](254) NULL,
	[WorkStart14] [varchar](254) NULL,
	[WorkName7] [varchar](254) NULL,
	[WorkName15] [varchar](254) NULL,
	[WorkIPAdd7] [varchar](254) NULL,
	[WorkIPAdd19] [varchar](254) NULL,
	[WorkHardSpecs8] [varchar](254) NULL,
	[WorkHardSpecs18] [varchar](254) NULL,
	[WebServStartup16] [varchar](254) NULL,
	[WebServShutdown18] [varchar](254) NULL,
	[WebServName5] [varchar](254) NULL,
	[WebServName12] [varchar](254) NULL,
	[WebServLoc7] [varchar](254) NULL,
	[WebServIP5] [varchar](254) NULL,
	[WebServIP12] [varchar](254) NULL,
	[WebServHardSpecs7] [varchar](254) NULL,
	[WebServHardSpecs16] [varchar](254) NULL,
	[WebServAdmin8] [varchar](254) NULL,
	[WebServAdmin17] [varchar](254) NULL,
	[WebInstall17] [text] NULL,
	[WebIIS] [varchar](254) NULL,
	[WebDBMgmt2] [varchar](254) NULL,
	[WebBackup5] [varchar](254) NULL,
	[TestServStartup20] [varchar](254) NULL,
	[TestServStartup] [varchar](254) NULL,
	[TestServSoftSpecs10] [varchar](254) NULL,
	[TestServShutdown5] [varchar](254) NULL,
	[TestServName8] [varchar](254) NULL,
	[TestServName18] [varchar](254) NULL,
	[TestServLoc20] [varchar](254) NULL,
	[TestServIP18] [varchar](254) NULL,
	[TestServAdmin] [varchar](254) NULL,
	[TestIIS14] [varchar](254) NULL,
	[TestDBMgmt20] [varchar](254) NULL,
	[TestDBA13] [varchar](254) NULL,
	[TestBackup13] [varchar](254) NULL,
	[ProdServStartup15] [varchar](254) NULL,
	[ProdServName9] [varchar](254) NULL,
	[ProdServName14] [varchar](254) NULL,
	[ProdServLoc10] [varchar](254) NULL,
	[ProdServHardSpecs9] [varchar](254) NULL,
	[ProdServAdmin20] [varchar](254) NULL,
	[ProdInstall6] [text] NULL,
	[ProdIIS7] [varchar](254) NULL,
	[ProdIIS20] [varchar](254) NULL,
	[ProdDBMgmt9] [varchar](254) NULL,
	[ProdDBMgmt14] [varchar](254) NULL,
	[ProdDBA8] [varchar](254) NULL,
	[ProdDB19] [varchar](254) NULL,
	[ProdBackup17] [varchar](254) NULL,
	[DevServSoftSpecs18] [varchar](254) NULL,
	[DevServShutdown4] [varchar](254) NULL,
	[DevServShutdown17] [varchar](254) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblApps2]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblApps2](
	[DevServName10] [varchar](254) NULL,
	[DevServLoc6] [varchar](254) NULL,
	[DevServLoc15] [varchar](254) NULL,
	[DevServIP11] [varchar](254) NULL,
	[DevServHardSpecs7] [varchar](254) NULL,
	[DevServHardSpecs14] [varchar](254) NULL,
	[DevServAdmin7] [varchar](254) NULL,
	[DevInstall20] [text] NULL,
	[DevIIS5] [varchar](254) NULL,
	[DevDBA6] [varchar](254) NULL,
	[DBServStartup16] [varchar](254) NULL,
	[DBServSoftSpecs11] [varchar](254) NULL,
	[DBServShutdown17] [varchar](254) NULL,
	[DBServName14] [varchar](254) NULL,
	[DBServLoc7] [varchar](254) NULL,
	[DBServLoc11] [varchar](254) NULL,
	[DBServIP12] [varchar](254) NULL,
	[DBServHardSpecs6] [varchar](254) NULL,
	[DBServAdmin18] [varchar](254) NULL,
	[DBIIS3] [varchar](254) NULL,
	[DBIIS15] [varchar](254) NULL,
	[DBIIS] [varchar](254) NULL,
	[DBDBMgmt7] [varchar](254) NULL,
	[DBDBA4] [varchar](254) NULL,
	[DBDBA14] [varchar](254) NULL,
	[DBBackup] [varchar](254) NULL,
	[Backup6] [varchar](254) NULL,
	[Backup16] [varchar](254) NULL,
	[Backup] [varchar](254) NULL,
	[AppVendorName] [varchar](254) NULL,
	[AppUserContact] [varchar](254) NULL,
	[AppServStartup18] [varchar](254) NULL,
	[AppServSoftSpecs11] [varchar](254) NULL,
	[AppServName20] [varchar](254) NULL,
	[AppServLoc18] [varchar](254) NULL,
	[AppServAdmin6] [varchar](254) NULL,
	[AppInstall5] [text] NULL,
	[AppInstall12] [text] NULL,
	[AppIIS7] [varchar](254) NULL,
	[AppIIS20] [varchar](254) NULL,
	[AppDBMgmt12] [varchar](254) NULL,
	[AppDBA8] [varchar](254) NULL,
	[AppDB19] [varchar](254) NULL,
	[AppBackup16] [varchar](254) NULL,
	[DevServName11] [varchar](254) NULL,
	[DevServLoc7] [varchar](254) NULL,
	[DevServLoc16] [varchar](254) NULL,
	[DevServIP12] [varchar](254) NULL,
	[DevServHardSpecs8] [varchar](254) NULL,
	[DevServHardSpecs15] [varchar](254) NULL,
	[DevServAdmin8] [varchar](254) NULL,
	[DevInstall10] [text] NULL,
	[DevIIS6] [varchar](254) NULL,
	[DevDBA7] [varchar](254) NULL,
	[DBServStartup17] [varchar](254) NULL,
	[DBServSoftSpecs12] [varchar](254) NULL,
	[DBServShutdown18] [varchar](254) NULL,
	[DBServName15] [varchar](254) NULL,
	[DBServLoc8] [varchar](254) NULL,
	[DBServLoc12] [varchar](254) NULL,
	[DBServIP13] [varchar](254) NULL,
	[DBServHardSpecs7] [varchar](254) NULL,
	[DBServAdmin19] [varchar](254) NULL,
	[DBIIS4] [varchar](254) NULL,
	[DBIIS16] [varchar](254) NULL,
	[DBDBMgmt8] [varchar](254) NULL,
	[DBDBA5] [varchar](254) NULL,
	[DBDBA15] [varchar](254) NULL,
	[DBDBA] [varchar](254) NULL,
	[Backup7] [varchar](254) NULL,
	[Backup17] [varchar](254) NULL,
	[AppSupContExp] [varchar](254) NULL,
	[AppServStartup19] [varchar](254) NULL,
	[AppServSoftSpecs2] [varchar](254) NULL,
	[AppServSoftSpecs12] [varchar](254) NULL,
	[AppServShutdown20] [varchar](254) NULL,
	[AppServName10] [varchar](254) NULL,
	[AppServLoc19] [varchar](254) NULL,
	[AppServIP2] [varchar](254) NULL,
	[AppServAdmin7] [varchar](254) NULL,
	[AppInstall6] [text] NULL,
	[AppInstall13] [text] NULL,
	[AppIIS8] [varchar](254) NULL,
	[AppIIS10] [varchar](254) NULL,
	[AppIIS] [varchar](254) NULL,
	[AppDBMgmt13] [varchar](254) NULL,
	[AppBackup2] [varchar](254) NULL,
	[AppBackup17] [varchar](254) NULL,
	[DevServName12] [varchar](254) NULL,
	[DevServLoc8] [varchar](254) NULL,
	[DevServLoc17] [varchar](254) NULL,
	[DevServIP13] [varchar](254) NULL,
	[DevServHardSpecs9] [varchar](254) NULL,
	[DevServHardSpecs16] [varchar](254) NULL,
	[DevServAdmin9] [varchar](254) NULL,
	[DevInstall11] [text] NULL,
	[DevIIS7] [varchar](254) NULL,
	[DevDBA8] [varchar](254) NULL,
	[DevDB19] [varchar](254) NULL,
	[DevBackup] [varchar](254) NULL,
	[DBServStartup2] [varchar](254) NULL,
	[DBServStartup18] [varchar](254) NULL,
	[DBServSoftSpecs13] [varchar](254) NULL,
	[DBServShutdown19] [varchar](254) NULL,
	[DBServName16] [varchar](254) NULL,
	[DBServLoc9] [varchar](254) NULL,
	[DBServLoc13] [varchar](254) NULL,
	[DBServIP14] [varchar](254) NULL,
	[DBServHardSpecs8] [varchar](254) NULL,
	[DBIIS5] [varchar](254) NULL,
	[DBIIS17] [varchar](254) NULL,
	[DBDBMgmt9] [varchar](254) NULL,
	[DBDBA6] [varchar](254) NULL,
	[DBDBA16] [varchar](254) NULL,
	[DBBackup20] [varchar](254) NULL,
	[Backup8] [varchar](254) NULL,
	[Backup18] [varchar](254) NULL,
	[Attachment] [text] NULL,
	[AppServSoftSpecs3] [varchar](254) NULL,
	[AppServSoftSpecs13] [varchar](254) NULL,
	[AppServShutdown10] [varchar](254) NULL,
	[AppServName2] [varchar](254) NULL,
	[AppServName11] [varchar](254) NULL,
	[AppServIP3] [varchar](254) NULL,
	[AppServIP] [varchar](254) NULL,
	[AppServAdmin8] [varchar](254) NULL,
	[AppServAdmin20] [varchar](254) NULL,
	[AppInstall7] [text] NULL,
	[AppInstall14] [text] NULL,
	[AppIIS9] [varchar](254) NULL,
	[AppIIS11] [varchar](254) NULL,
	[AppDBMgmt14] [varchar](254) NULL,
	[AppDBA] [varchar](254) NULL,
	[AppBackup3] [varchar](254) NULL,
	[AppBackup18] [varchar](254) NULL,
	[DevServName13] [varchar](254) NULL,
	[DevServLoc9] [varchar](254) NULL,
	[DevServLoc18] [varchar](254) NULL,
	[DevServIP14] [varchar](254) NULL,
	[DevServHardSpecs17] [varchar](254) NULL,
	[DevInstall12] [text] NULL,
	[DevIIS8] [varchar](254) NULL,
	[DevBackup20] [varchar](254) NULL,
	[DBServStartup3] [varchar](254) NULL,
	[DBServStartup19] [varchar](254) NULL,
	[DBServStartup] [varchar](254) NULL,
	[DBServSoftSpecs14] [varchar](254) NULL,
	[DBServName17] [varchar](254) NULL,
	[DBServName] [varchar](254) NULL,
	[DBServLoc14] [varchar](254) NULL,
	[DBServIP15] [varchar](254) NULL,
	[DBServHardSpecs9] [varchar](254) NULL,
	[DBServHardSpecs20] [varchar](254) NULL,
	[DBIIS6] [varchar](254) NULL,
	[DBIIS18] [varchar](254) NULL,
	[DBDBA7] [varchar](254) NULL,
	[DBDBA17] [varchar](254) NULL,
	[DBBackup10] [varchar](254) NULL,
	[Backup9] [varchar](254) NULL,
	[Backup19] [varchar](254) NULL,
	[AppUser] [varchar](254) NULL,
	[AppSupContact] [varchar](254) NULL,
	[AppServSoftSpecs4] [varchar](254) NULL,
	[AppServSoftSpecs14] [varchar](254) NULL,
	[AppServShutdown11] [varchar](254) NULL,
	[AppServName3] [varchar](254) NULL,
	[AppServName12] [varchar](254) NULL,
	[AppServLoc2] [varchar](254) NULL,
	[AppServIP4] [varchar](254) NULL,
	[AppServHardSpecs20] [varchar](254) NULL,
	[AppServHardSpecs] [varchar](254) NULL,
	[AppServAdmin9] [varchar](254) NULL,
	[AppServAdmin10] [varchar](254) NULL,
	[AppInstall8] [text] NULL,
	[AppInstall15] [text] NULL,
	[AppIIS12] [varchar](254) NULL,
	[AppDBMgmt15] [varchar](254) NULL,
	[AppBackup4] [varchar](254) NULL,
	[AppBackup19] [varchar](254) NULL,
	[DevServName14] [varchar](254) NULL,
	[DevServName] [varchar](254) NULL,
	[DevServLoc19] [varchar](254) NULL,
	[DevServIP15] [varchar](254) NULL,
	[DevServHardSpecs18] [varchar](254) NULL,
	[DevInstall13] [text] NULL,
	[DevIIS9] [varchar](254) NULL,
	[DevIIS20] [varchar](254) NULL,
	[DevBackup10] [varchar](254) NULL,
	[DBServStartup4] [varchar](254) NULL,
	[DBServSoftSpecs15] [varchar](254) NULL,
	[DBServShutdown] [varchar](254) NULL,
	[DBServName18] [varchar](254) NULL,
	[DBServLoc15] [varchar](254) NULL,
	[DBServIP16] [varchar](254) NULL,
	[DBServHardSpecs10] [varchar](254) NULL,
	[DBInstall20] [text] NULL,
	[DBIIS7] [varchar](254) NULL,
	[DBIIS19] [varchar](254) NULL,
	[DBDBA8] [varchar](254) NULL,
	[DBDBA18] [varchar](254) NULL,
	[DBBackup11] [varchar](254) NULL,
	[AppServSoftSpecs5] [varchar](254) NULL,
	[AppServSoftSpecs15] [varchar](254) NULL,
	[AppServShutdown12] [varchar](254) NULL,
	[AppServName4] [varchar](254) NULL,
	[AppServName13] [varchar](254) NULL,
	[AppServLoc3] [varchar](254) NULL,
	[AppServIP5] [varchar](254) NULL,
	[AppServHardSpecs10] [varchar](254) NULL,
	[AppServAdmin11] [varchar](254) NULL,
	[AppInstall9] [text] NULL,
	[AppInstall16] [text] NULL,
	[AppIIS13] [varchar](254) NULL,
	[AppDBMgmt2] [varchar](254) NULL,
	[AppDBMgmt16] [varchar](254) NULL,
	[AppDBMgmt] [varchar](254) NULL,
	[AppBackup5] [varchar](254) NULL,
	[DevServName2] [varchar](254) NULL,
	[DevServName15] [varchar](254) NULL,
	[DevServIP16] [varchar](254) NULL,
	[DevServHardSpecs19] [varchar](254) NULL,
	[DevServAdmin20] [varchar](254) NULL,
	[DevInstall14] [text] NULL,
	[DevIIS10] [varchar](254) NULL,
	[DevBackup11] [varchar](254) NULL,
	[DBServStartup5] [varchar](254) NULL,
	[DBServSoftSpecs16] [varchar](254) NULL,
	[DBServName19] [varchar](254) NULL,
	[DBServLoc16] [varchar](254) NULL,
	[DBServIP17] [varchar](254) NULL,
	[DBServHardSpecs11] [varchar](254) NULL,
	[DBInstall10] [text] NULL,
	[DBIIS8] [varchar](254) NULL,
	[DBDBA9] [varchar](254) NULL,
	[DBDBA19] [varchar](254) NULL,
	[DBBackup12] [varchar](254) NULL,
	[AppSupContNo] [varchar](254) NULL,
	[AppServSoftSpecs6] [varchar](254) NULL,
	[AppServSoftSpecs16] [varchar](254) NULL,
	[AppServShutdown2] [varchar](254) NULL,
	[AppServShutdown13] [varchar](254) NULL,
	[AppServName5] [varchar](254) NULL,
	[AppServName14] [varchar](254) NULL,
	[AppServLoc4] [varchar](254) NULL,
	[AppServLoc] [varchar](254) NULL,
	[AppServIP6] [varchar](254) NULL,
	[AppServIP20] [varchar](254) NULL,
	[AppServHardSpecs2] [varchar](254) NULL,
	[AppServHardSpecs11] [varchar](254) NULL,
	[AppServAdmin12] [varchar](254) NULL,
	[AppName] [varchar](254) NULL,
	[AppInstall17] [text] NULL,
	[AppIIS14] [varchar](254) NULL,
	[AppDBMgmt3] [varchar](254) NULL,
	[AppDBMgmt17] [varchar](254) NULL,
	[AppBackup6] [varchar](254) NULL,
	[DevServName3] [varchar](254) NULL,
	[DevServName16] [varchar](254) NULL,
	[DevServIP2] [varchar](254) NULL,
	[DevServIP17] [varchar](254) NULL,
	[DevServAdmin10] [varchar](254) NULL,
	[DevInstall15] [text] NULL,
	[DevIIS11] [varchar](254) NULL,
	[DevDBMgmt20] [varchar](254) NULL,
	[DevBackup2] [varchar](254) NULL,
	[DevBackup12] [varchar](254) NULL,
	[DBServStartup6] [varchar](254) NULL,
	[DBServSoftSpecs17] [varchar](254) NULL,
	[DBServLoc17] [varchar](254) NULL,
	[DBServIP18] [varchar](254) NULL,
	[DBServHardSpecs12] [varchar](254) NULL,
	[DBServHardSpecs] [varchar](254) NULL,
	[DBInstall11] [text] NULL,
	[DBIIS9] [varchar](254) NULL,
	[DBDBMgmt20] [varchar](254) NULL,
	[DBBackup13] [varchar](254) NULL,
	[AppServSoftSpecs7] [varchar](254) NULL,
	[AppServSoftSpecs17] [varchar](254) NULL,
	[AppServShutdown3] [varchar](254) NULL,
	[AppServShutdown14] [varchar](254) NULL,
	[AppServName6] [varchar](254) NULL,
	[AppServName15] [varchar](254) NULL,
	[AppServLoc5] [varchar](254) NULL,
	[AppServIP7] [varchar](254) NULL,
	[AppServIP10] [varchar](254) NULL,
	[AppServHardSpecs3] [varchar](254) NULL,
	[AppServHardSpecs12] [varchar](254) NULL,
	[AppServAdmin13] [varchar](254) NULL,
	[AppInstall18] [text] NULL,
	[AppIIS15] [varchar](254) NULL,
	[AppDBMgmt4] [varchar](254) NULL,
	[AppDBMgmt18] [varchar](254) NULL,
	[AppBackup7] [varchar](254) NULL,
	[DevServName4] [varchar](254) NULL,
	[DevServName17] [varchar](254) NULL,
	[DevServIP3] [varchar](254) NULL,
	[DevServIP18] [varchar](254) NULL,
	[DevServAdmin11] [varchar](254) NULL,
	[DevInstall2] [text] NULL,
	[DevInstall16] [text] NULL,
	[DevIIS12] [varchar](254) NULL,
	[DevDBMgmt10] [varchar](254) NULL,
	[DevDBA11] [varchar](254) NULL,
	[DevBackup3] [varchar](254) NULL,
	[DevBackup13] [varchar](254) NULL,
	[DBServStartup7] [varchar](254) NULL,
	[DBServSoftSpecs18] [varchar](254) NULL,
	[DBServLoc18] [varchar](254) NULL,
	[DBServIP19] [varchar](254) NULL,
	[DBServHardSpecs13] [varchar](254) NULL,
	[DBInstall2] [text] NULL,
	[DBInstall12] [text] NULL,
	[DBDBMgmt10] [varchar](254) NULL,
	[DBBackup14] [varchar](254) NULL,
	[AppVendorContactInfo] [varchar](254) NULL,
	[AppServSoftSpecs8] [varchar](254) NULL,
	[AppServSoftSpecs18] [varchar](254) NULL,
	[AppServShutdown4] [varchar](254) NULL,
	[AppServShutdown15] [varchar](254) NULL,
	[AppServName7] [varchar](254) NULL,
	[AppServName16] [varchar](254) NULL,
	[AppServLoc6] [varchar](254) NULL,
	[AppServIP8] [varchar](254) NULL,
	[AppServIP11] [varchar](254) NULL,
	[AppServHardSpecs4] [varchar](254) NULL,
	[AppServHardSpecs13] [varchar](254) NULL,
	[AppServAdmin14] [varchar](254) NULL,
	[AppInstall19] [text] NULL,
	[AppIIS16] [varchar](254) NULL,
	[AppDBMgmt5] [varchar](254) NULL,
	[AppDBMgmt19] [varchar](254) NULL,
	[AppDB20] [varchar](254) NULL,
	[AppBackup8] [varchar](254) NULL,
	[AppBackup] [varchar](254) NULL,
	[DevServName5] [varchar](254) NULL,
	[DevServName18] [varchar](254) NULL,
	[DevServIP4] [varchar](254) NULL,
	[DevServIP19] [varchar](254) NULL,
	[DevServAdmin12] [varchar](254) NULL,
	[DevInstall3] [text] NULL,
	[DevInstall17] [text] NULL,
	[DevIIS13] [varchar](254) NULL,
	[DevDBMgmt2] [varchar](254) NULL,
	[DevDBMgmt11] [varchar](254) NULL,
	[DevDBA12] [varchar](254) NULL,
	[DevDB9] [varchar](254) NULL,
	[DevBackup4] [varchar](254) NULL,
	[DevBackup14] [varchar](254) NULL,
	[DBServStartup8] [varchar](254) NULL,
	[DBServSoftSpecs19] [varchar](254) NULL,
	[DBServShutdown2] [varchar](254) NULL,
	[DBServLoc19] [varchar](254) NULL,
	[DBServHardSpecs14] [varchar](254) NULL,
	[DBServAdmin20] [varchar](254) NULL,
	[DBInstall3] [text] NULL,
	[DBInstall13] [text] NULL,
	[DBDBMgmt11] [varchar](254) NULL,
	[DBBackup15] [varchar](254) NULL,
	[AppServStartup20] [varchar](254) NULL,
	[AppServStartup2] [varchar](254) NULL,
	[AppServSoftSpecs9] [varchar](254) NULL,
	[AppServSoftSpecs19] [varchar](254) NULL,
	[AppServShutdown5] [varchar](254) NULL,
	[AppServShutdown16] [varchar](254) NULL,
	[AppServName8] [varchar](254) NULL,
	[AppServName17] [varchar](254) NULL,
	[AppServLoc7] [varchar](254) NULL,
	[AppServLoc20] [varchar](254) NULL,
	[AppServIP9] [varchar](254) NULL,
	[AppServIP12] [varchar](254) NULL,
	[AppServHardSpecs5] [varchar](254) NULL,
	[AppServHardSpecs14] [varchar](254) NULL,
	[AppServAdmin15] [varchar](254) NULL,
	[AppServAdmin] [varchar](254) NULL,
	[AppInstall] [text] NULL,
	[AppIIS17] [varchar](254) NULL,
	[AppDBMgmt6] [varchar](254) NULL,
	[AppDB10] [varchar](254) NULL,
	[AppBackup9] [varchar](254) NULL,
	[DevServName6] [varchar](254) NULL,
	[DevServName19] [varchar](254) NULL,
	[DevServIP5] [varchar](254) NULL,
	[DevServAdmin13] [varchar](254) NULL,
	[DevInstall4] [text] NULL,
	[DevInstall18] [text] NULL,
	[DevIIS14] [varchar](254) NULL,
	[DevDBMgmt3] [varchar](254) NULL,
	[DevDBMgmt12] [varchar](254) NULL,
	[DevDBA13] [varchar](254) NULL,
	[DevDB20] [varchar](254) NULL,
	[DevBackup5] [varchar](254) NULL,
	[DevBackup15] [varchar](254) NULL,
	[DBServStartup9] [varchar](254) NULL,
	[DBServSoftSpecs2] [varchar](254) NULL,
	[DBServShutdown3] [varchar](254) NULL,
	[DBServShutdown20] [varchar](254) NULL,
	[DBServName2] [varchar](254) NULL,
	[DBServIP2] [varchar](254) NULL,
	[DBServHardSpecs15] [varchar](254) NULL,
	[DBServAdmin2] [varchar](254) NULL,
	[DBServAdmin10] [varchar](254) NULL,
	[DBInstall4] [text] NULL,
	[DBInstall14] [text] NULL,
	[DBDBMgmt12] [varchar](254) NULL,
	[DBBackup2] [varchar](254) NULL,
	[DBBackup16] [varchar](254) NULL,
	[AppServStartup3] [varchar](254) NULL,
	[AppServStartup10] [varchar](254) NULL,
	[AppServSoftSpecs] [varchar](254) NULL,
	[AppServShutdown6] [varchar](254) NULL,
	[AppServShutdown17] [varchar](254) NULL,
	[AppServName9] [varchar](254) NULL,
	[AppServName18] [varchar](254) NULL,
	[AppServLoc8] [varchar](254) NULL,
	[AppServLoc10] [varchar](254) NULL,
	[AppServIP13] [varchar](254) NULL,
	[AppServHardSpecs6] [varchar](254) NULL,
	[AppServHardSpecs15] [varchar](254) NULL,
	[AppServAdmin16] [varchar](254) NULL,
	[AppInstallDate] [varchar](254) NULL,
	[AppIIS18] [varchar](254) NULL,
	[AppDBMgmt7] [varchar](254) NULL,
	[AppDB11] [varchar](254) NULL,
	[DevServName7] [varchar](254) NULL,
	[DevServLoc] [varchar](254) NULL,
	[DevServIP6] [varchar](254) NULL,
	[DevServAdmin14] [varchar](254) NULL,
	[DevInstall5] [text] NULL,
	[DevInstall19] [text] NULL,
	[DevIIS15] [varchar](254) NULL,
	[DevDBMgmt4] [varchar](254) NULL,
	[DevDBMgmt13] [varchar](254) NULL,
	[DevDBA14] [varchar](254) NULL,
	[DevDB10] [varchar](254) NULL,
	[DevBackup6] [varchar](254) NULL,
	[DevBackup16] [varchar](254) NULL,
	[DBServStartup20] [varchar](254) NULL,
	[DBServSoftSpecs3] [varchar](254) NULL,
	[DBServShutdown4] [varchar](254) NULL,
	[DBServShutdown10] [varchar](254) NULL,
	[DBServName3] [varchar](254) NULL,
	[DBServIP3] [varchar](254) NULL,
	[DBServHardSpecs16] [varchar](254) NULL,
	[DBServAdmin3] [varchar](254) NULL,
	[DBServAdmin11] [varchar](254) NULL,
	[DBInstall5] [text] NULL,
	[DBInstall15] [text] NULL,
	[DBDBMgmt13] [varchar](254) NULL,
	[DBBackup3] [varchar](254) NULL,
	[DBBackup17] [varchar](254) NULL,
	[Backup20] [varchar](254) NULL,
	[AppServStartup4] [varchar](254) NULL,
	[AppServStartup11] [varchar](254) NULL,
	[AppServShutdown7] [varchar](254) NULL,
	[AppServShutdown18] [varchar](254) NULL,
	[AppServShutdown] [varchar](254) NULL,
	[AppServName19] [varchar](254) NULL,
	[AppServLoc9] [varchar](254) NULL,
	[AppServLoc11] [varchar](254) NULL,
	[AppServIP14] [varchar](254) NULL,
	[AppServHardSpecs7] [varchar](254) NULL,
	[AppServHardSpecs16] [varchar](254) NULL,
	[AppServAdmin17] [varchar](254) NULL,
	[AppIIS19] [varchar](254) NULL,
	[AppDBMgmt8] [varchar](254) NULL,
	[AppDB12] [varchar](254) NULL,
	[AppBackup20] [varchar](254) NULL,
	[DevServName8] [varchar](254) NULL,
	[DevServLoc20] [varchar](254) NULL,
	[DevServIP7] [varchar](254) NULL,
	[DevServAdmin15] [varchar](254) NULL,
	[DevServAdmin] [varchar](254) NULL,
	[DevInstall6] [text] NULL,
	[DevIIS16] [varchar](254) NULL,
	[DevDBMgmt5] [varchar](254) NULL,
	[DevDBMgmt14] [varchar](254) NULL,
	[DevDBA15] [varchar](254) NULL,
	[DevBackup7] [varchar](254) NULL,
	[DevBackup17] [varchar](254) NULL,
	[DBServStartup10] [varchar](254) NULL,
	[DBServSoftSpecs4] [varchar](254) NULL,
	[DBServShutdown5] [varchar](254) NULL,
	[DBServShutdown11] [varchar](254) NULL,
	[DBServName4] [varchar](254) NULL,
	[DBServIP4] [varchar](254) NULL,
	[DBServHardSpecs17] [varchar](254) NULL,
	[DBServAdmin4] [varchar](254) NULL,
	[DBServAdmin12] [varchar](254) NULL,
	[DBInstall6] [text] NULL,
	[DBInstall16] [text] NULL,
	[DBIIS20] [varchar](254) NULL,
	[DBDBMgmt14] [varchar](254) NULL,
	[DBBackup4] [varchar](254) NULL,
	[DBBackup18] [varchar](254) NULL,
	[Backup10] [varchar](254) NULL,
	[AppUser2] [varchar](254) NULL,
	[AppServStartup5] [varchar](254) NULL,
	[AppServStartup12] [varchar](254) NULL,
	[AppServShutdown8] [varchar](254) NULL,
	[AppServShutdown19] [varchar](254) NULL,
	[AppServName] [varchar](254) NULL,
	[AppServLoc12] [varchar](254) NULL,
	[AppServIP15] [varchar](254) NULL,
	[AppServHardSpecs8] [varchar](254) NULL,
	[AppServHardSpecs17] [varchar](254) NULL,
	[AppServAdmin18] [varchar](254) NULL,
	[AppDBMgmt9] [varchar](254) NULL,
	[AppDBA2] [varchar](254) NULL,
	[AppDB9] [varchar](254) NULL,
	[AppDB13] [varchar](254) NULL,
	[AppBackup10] [varchar](254) NULL,
	[DevServName9] [varchar](254) NULL,
	[DevServLoc10] [varchar](254) NULL,
	[DevServIP8] [varchar](254) NULL,
	[DevServHardSpecs20] [varchar](254) NULL,
	[DevServHardSpecs2] [varchar](254) NULL,
	[DevServAdmin2] [varchar](254) NULL,
	[DevServAdmin16] [varchar](254) NULL,
	[DevInstall7] [text] NULL,
	[DevIIS17] [varchar](254) NULL,
	[DevDBMgmt6] [varchar](254) NULL,
	[DevDBMgmt15] [varchar](254) NULL,
	[DevDBA16] [varchar](254) NULL,
	[DevBackup8] [varchar](254) NULL,
	[DevBackup18] [varchar](254) NULL,
	[DBServStartup11] [varchar](254) NULL,
	[DBServSoftSpecs5] [varchar](254) NULL,
	[DBServSoftSpecs] [varchar](254) NULL,
	[DBServShutdown6] [varchar](254) NULL,
	[DBServShutdown12] [varchar](254) NULL,
	[DBServName5] [varchar](254) NULL,
	[DBServName20] [varchar](254) NULL,
	[DBServLoc2] [varchar](254) NULL,
	[DBServIP5] [varchar](254) NULL,
	[DBServIP] [varchar](254) NULL,
	[DBServHardSpecs18] [varchar](254) NULL,
	[DBServAdmin5] [varchar](254) NULL,
	[DBServAdmin13] [varchar](254) NULL,
	[DBInstall7] [text] NULL,
	[DBInstall17] [text] NULL,
	[DBIIS10] [varchar](254) NULL,
	[DBDBMgmt2] [varchar](254) NULL,
	[DBDBMgmt15] [varchar](254) NULL,
	[DBDBA20] [varchar](254) NULL,
	[DBBackup5] [varchar](254) NULL,
	[DBBackup19] [varchar](254) NULL,
	[Backup11] [varchar](254) NULL,
	[AppServStartup6] [varchar](254) NULL,
	[AppServStartup13] [varchar](254) NULL,
	[AppServShutdown9] [varchar](254) NULL,
	[AppServLoc13] [varchar](254) NULL,
	[AppServIP16] [varchar](254) NULL,
	[AppServHardSpecs9] [varchar](254) NULL,
	[AppServHardSpecs18] [varchar](254) NULL,
	[AppServAdmin19] [varchar](254) NULL,
	[AppInstaller] [varchar](254) NULL,
	[AppIIS2] [varchar](254) NULL,
	[AppDBA3] [varchar](254) NULL,
	[AppDB14] [varchar](254) NULL,
	[AppBackup11] [varchar](254) NULL,
	[DevServLoc2] [varchar](254) NULL,
	[DevServLoc11] [varchar](254) NULL,
	[DevServIP9] [varchar](254) NULL,
	[DevServHardSpecs3] [varchar](254) NULL,
	[DevServHardSpecs10] [varchar](254) NULL,
	[DevServHardSpecs] [varchar](254) NULL,
	[DevServAdmin3] [varchar](254) NULL,
	[DevServAdmin17] [varchar](254) NULL,
	[DevInstall8] [text] NULL,
	[DevInstall] [text] NULL,
	[DevIIS18] [varchar](254) NULL,
	[DevDBMgmt7] [varchar](254) NULL,
	[DevDBMgmt16] [varchar](254) NULL,
	[DevDBA2] [varchar](254) NULL,
	[DevDBA17] [varchar](254) NULL,
	[DevBackup9] [varchar](254) NULL,
	[DevBackup19] [varchar](254) NULL,
	[DBServStartup12] [varchar](254) NULL,
	[DBServSoftSpecs6] [varchar](254) NULL,
	[DBServShutdown7] [varchar](254) NULL,
	[DBServShutdown13] [varchar](254) NULL,
	[DBServName6] [varchar](254) NULL,
	[DBServName10] [varchar](254) NULL,
	[DBServLoc3] [varchar](254) NULL,
	[DBServLoc] [varchar](254) NULL,
	[DBServIP6] [varchar](254) NULL,
	[DBServHardSpecs2] [varchar](254) NULL,
	[DBServHardSpecs19] [varchar](254) NULL,
	[DBServAdmin6] [varchar](254) NULL,
	[DBServAdmin14] [varchar](254) NULL,
	[DBInstall8] [text] NULL,
	[DBInstall18] [text] NULL,
	[DBIIS11] [varchar](254) NULL,
	[DBDBMgmt3] [varchar](254) NULL,
	[DBDBMgmt16] [varchar](254) NULL,
	[DBDBA10] [varchar](254) NULL,
	[DBBackup6] [varchar](254) NULL,
	[Backup2] [varchar](254) NULL,
	[Backup12] [varchar](254) NULL,
	[AppUserContact2] [varchar](254) NULL,
	[AppServStartup7] [varchar](254) NULL,
	[AppServStartup14] [varchar](254) NULL,
	[AppServLoc14] [varchar](254) NULL,
	[AppServIP17] [varchar](254) NULL,
	[AppServHardSpecs19] [varchar](254) NULL,
	[AppServAdmin2] [varchar](254) NULL,
	[AppIIS3] [varchar](254) NULL,
	[AppDBA4] [varchar](254) NULL,
	[AppDB15] [varchar](254) NULL,
	[AppBackup12] [varchar](254) NULL,
	[DevServLoc3] [varchar](254) NULL,
	[DevServLoc12] [varchar](254) NULL,
	[DevServIP] [varchar](254) NULL,
	[DevServHardSpecs4] [varchar](254) NULL,
	[DevServHardSpecs11] [varchar](254) NULL,
	[DevServAdmin4] [varchar](254) NULL,
	[DevServAdmin18] [varchar](254) NULL,
	[DevInstall9] [text] NULL,
	[DevIIS2] [varchar](254) NULL,
	[DevIIS19] [varchar](254) NULL,
	[DevDBMgmt8] [varchar](254) NULL,
	[DevDBMgmt17] [varchar](254) NULL,
	[DevDBA3] [varchar](254) NULL,
	[DevDBA18] [varchar](254) NULL,
	[DBServStartup13] [varchar](254) NULL,
	[DBServSoftSpecs7] [varchar](254) NULL,
	[DBServShutdown8] [varchar](254) NULL,
	[DBServShutdown14] [varchar](254) NULL,
	[DBServName7] [varchar](254) NULL,
	[DBServName11] [varchar](254) NULL,
	[DBServLoc4] [varchar](254) NULL,
	[DBServIP7] [varchar](254) NULL,
	[DBServIP20] [varchar](254) NULL,
	[DBServHardSpecs3] [varchar](254) NULL,
	[DBServAdmin7] [varchar](254) NULL,
	[DBServAdmin15] [varchar](254) NULL,
	[DBInstall9] [text] NULL,
	[DBInstall19] [text] NULL,
	[DBIIS12] [varchar](254) NULL,
	[DBDBMgmt4] [varchar](254) NULL,
	[DBDBMgmt17] [varchar](254) NULL,
	[DBDBMgmt] [varchar](254) NULL,
	[DBDBA11] [varchar](254) NULL,
	[DBBackup7] [varchar](254) NULL,
	[Backup3] [varchar](254) NULL,
	[Backup13] [varchar](254) NULL,
	[AppServStartup8] [varchar](254) NULL,
	[AppServStartup15] [varchar](254) NULL,
	[AppServLoc15] [varchar](254) NULL,
	[AppServIP18] [varchar](254) NULL,
	[AppServAdmin3] [varchar](254) NULL,
	[AppInstall20] [text] NULL,
	[AppInstall2] [text] NULL,
	[AppIIS4] [varchar](254) NULL,
	[AppDBMgmt20] [varchar](254) NULL,
	[AppDBA5] [varchar](254) NULL,
	[AppDB16] [varchar](254) NULL,
	[AppBackup13] [varchar](254) NULL,
	[DevServLoc4] [varchar](254) NULL,
	[DevServLoc13] [varchar](254) NULL,
	[DevServIP20] [varchar](254) NULL,
	[DevServHardSpecs5] [varchar](254) NULL,
	[DevServHardSpecs12] [varchar](254) NULL,
	[DevServAdmin5] [varchar](254) NULL,
	[DevServAdmin19] [varchar](254) NULL,
	[DevIIS3] [varchar](254) NULL,
	[DevIIS] [varchar](254) NULL,
	[DevDBMgmt9] [varchar](254) NULL,
	[DevDBMgmt18] [varchar](254) NULL,
	[DevDBA4] [varchar](254) NULL,
	[DBServStartup14] [varchar](254) NULL,
	[DBServSoftSpecs8] [varchar](254) NULL,
	[DBServSoftSpecs20] [varchar](254) NULL,
	[DBServShutdown9] [varchar](254) NULL,
	[DBServShutdown15] [varchar](254) NULL,
	[DBServName8] [varchar](254) NULL,
	[DBServName12] [varchar](254) NULL,
	[DBServLoc5] [varchar](254) NULL,
	[DBServLoc20] [varchar](254) NULL,
	[DBServIP8] [varchar](254) NULL,
	[DBServIP10] [varchar](254) NULL,
	[DBServHardSpecs4] [varchar](254) NULL,
	[DBServAdmin8] [varchar](254) NULL,
	[DBServAdmin16] [varchar](254) NULL,
	[DBServAdmin] [varchar](254) NULL,
	[DBIIS13] [varchar](254) NULL,
	[DBDBMgmt5] [varchar](254) NULL,
	[DBDBMgmt18] [varchar](254) NULL,
	[DBDBA2] [varchar](254) NULL,
	[DBDBA12] [varchar](254) NULL,
	[DBBackup8] [varchar](254) NULL,
	[Backup4] [varchar](254) NULL,
	[Backup14] [varchar](254) NULL,
	[AppServStartup9] [varchar](254) NULL,
	[AppServStartup16] [varchar](254) NULL,
	[AppServStartup] [varchar](254) NULL,
	[AppServSoftSpecs20] [varchar](254) NULL,
	[AppServLoc16] [varchar](254) NULL,
	[AppServIP19] [varchar](254) NULL,
	[AppServAdmin4] [varchar](254) NULL,
	[AppInstall3] [text] NULL,
	[AppInstall10] [text] NULL,
	[AppIIS5] [varchar](254) NULL,
	[AppDBMgmt10] [varchar](254) NULL,
	[AppDBA6] [varchar](254) NULL,
	[AppDB17] [varchar](254) NULL,
	[AppBackup14] [varchar](254) NULL,
	[DevServName20] [varchar](254) NULL,
	[DevServLoc5] [varchar](254) NULL,
	[DevServLoc14] [varchar](254) NULL,
	[DevServIP10] [varchar](254) NULL,
	[DevServHardSpecs6] [varchar](254) NULL,
	[DevServHardSpecs13] [varchar](254) NULL,
	[DevServAdmin6] [varchar](254) NULL,
	[DevIIS4] [varchar](254) NULL,
	[DevDBMgmt19] [varchar](254) NULL,
	[DevDBMgmt] [varchar](254) NULL,
	[DevDBA5] [varchar](254) NULL,
	[DevDBA] [varchar](254) NULL,
	[DBServStartup15] [varchar](254) NULL,
	[DBServSoftSpecs9] [varchar](254) NULL,
	[DBServSoftSpecs10] [varchar](254) NULL,
	[DBServShutdown16] [varchar](254) NULL,
	[DBServName9] [varchar](254) NULL,
	[DBServName13] [varchar](254) NULL,
	[DBServLoc6] [varchar](254) NULL,
	[DBServLoc10] [varchar](254) NULL,
	[DBServIP9] [varchar](254) NULL,
	[DBServIP11] [varchar](254) NULL,
	[DBServHardSpecs5] [varchar](254) NULL,
	[DBServAdmin9] [varchar](254) NULL,
	[DBServAdmin17] [varchar](254) NULL,
	[DBInstall] [text] NULL,
	[DBIIS2] [varchar](254) NULL,
	[DBIIS14] [varchar](254) NULL,
	[DBDBMgmt6] [varchar](254) NULL,
	[DBDBMgmt19] [varchar](254) NULL,
	[DBDBA3] [varchar](254) NULL,
	[DBDBA13] [varchar](254) NULL,
	[DBBackup9] [varchar](254) NULL,
	[Comments] [text] NULL,
	[Backup5] [varchar](254) NULL,
	[Backup15] [varchar](254) NULL,
	[AppVersion] [varchar](254) NULL,
	[AppVendorContact] [varchar](254) NULL,
	[AppServStartup17] [varchar](254) NULL,
	[AppServSoftSpecs10] [varchar](254) NULL,
	[AppServLoc17] [varchar](254) NULL,
	[AppServAdmin5] [varchar](254) NULL,
	[AppInstall4] [text] NULL,
	[AppInstall11] [text] NULL,
	[AppIIS6] [varchar](254) NULL,
	[AppDBMgmt11] [varchar](254) NULL,
	[AppDBA7] [varchar](254) NULL,
	[AppDB18] [varchar](254) NULL,
	[AppBackup15] [varchar](254) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TmpUser]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TmpUser](
	[uid] [smallint] NULL,
	[name] [sysname] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USA$]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USA$](
	[F1] [float] NOT NULL,
	[CityName ] [nvarchar](255) NULL,
	[StateName] [nvarchar](255) NULL,
	[Latitude ] [nvarchar](255) NULL,
	[Longitude] [nvarchar](255) NULL,
	[F6] [nvarchar](255) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserApplication]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserApplication](
	[UserApplicationId] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationId] [int] NULL,
	[UserId] [nvarchar](450) NULL,
 CONSTRAINT [PK_UserApplication] PRIMARY KEY CLUSTERED 
(
	[UserApplicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserCountry]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserCountry](
	[UserCountryId] [int] IDENTITY(1,1) NOT NULL,
	[CountryId] [int] NULL,
	[UserId] [nvarchar](450) NULL,
 CONSTRAINT [PK_UserCountry] PRIMARY KEY CLUSTERED 
(
	[UserCountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserDataCenter]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserDataCenter](
	[UserDataCenterId] [int] IDENTITY(1,1) NOT NULL,
	[DataCenterId] [int] NULL,
	[UserId] [nvarchar](450) NULL,
 CONSTRAINT [PK_UserDataCenter] PRIMARY KEY CLUSTERED 
(
	[UserDataCenterId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserDepartment]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserDepartment](
	[UserDepartmentId] [int] IDENTITY(1,1) NOT NULL,
	[DepartmentId] [int] NULL,
	[UserId] [nvarchar](450) NULL,
 CONSTRAINT [PK_UserDepartment] PRIMARY KEY CLUSTERED 
(
	[UserDepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [Laimonas.Simutis].[ServerImport]    Script Date: 7/7/2020 3:33:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Laimonas.Simutis].[ServerImport](
	[ADAMLDAP01] [nvarchar](255) NULL
) ON [PRIMARY]

GO
INSERT [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES (N'00000000000000_CreateIdentitySchema', N'2.0.1-rtm-125')
INSERT [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES (N'20190422143330_User_CountryId_CountryName', N'2.0.1-rtm-125')
INSERT [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES (N'20190422150139_User_CompanyId_CompanyName', N'2.0.1-rtm-125')
SET IDENTITY_INSERT [dbo].[ADGroup] ON 

INSERT [dbo].[ADGroup] ([ADGroupID], [GroupName], [GroupPath]) VALUES (1, N'groupname', N'grouppath')
INSERT [dbo].[ADGroup] ([ADGroupID], [GroupName], [GroupPath]) VALUES (6, N'groupname', N'grouppath')
INSERT [dbo].[ADGroup] ([ADGroupID], [GroupName], [GroupPath]) VALUES (1002, N'groupname', N'grouppath')
INSERT [dbo].[ADGroup] ([ADGroupID], [GroupName], [GroupPath]) VALUES (1005, NULL, NULL)
SET IDENTITY_INSERT [dbo].[ADGroup] OFF
SET IDENTITY_INSERT [dbo].[Application] ON 

INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6071, N'masoomfarishta', N'ver', N'short', N'long', N'instal', NULL, N'phone', NULL, N'account', NULL, N'url', 8, N'comment', 1, N'abc', N'abc', 2, 1, N'name', N'url', 3, 1, 1, NULL, NULL, 1, N'firewal', N'ldap', NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6072, N'test city', N'ver', N'short', N'long', N'instal', CAST(0x0000ABAB010A0810 AS DateTime), N'phone', NULL, N'Account', CAST(0x0000ABAB010A0810 AS DateTime), N'url', 9, N'comment', 1, N'abc', N'abc', 2, 1, N'name', N'url', 2, 1, 1, CAST(0x0000ABAB010A0810 AS DateTime), NULL, 1, N'firewal', N'ldap', NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6073, N'abcd', N'ver', N'short', N'long', N'instal', CAST(0x0000ABF00133E2D2 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF00133E664 AS DateTime), N'url', 2, NULL, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6074, N'abcxyzjjjjj', N'ver', N'short', N'long', N'instal', CAST(0x0000ABF00134D630 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF00134D630 AS DateTime), N'url', 2, N'comment', 1, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6077, N'Masoom', N'ver', N'short', N'long', N'install', CAST(0x0000ABF001366E48 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF001366F2B AS DateTime), N'url', 2, N'comment', 1, N'abc', N'abc', 2, 0, NULL, NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6078, N'usman', N'zaman', N'short', N'long', N'instal', CAST(0x0000ABF001374BF8 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF001374BF8 AS DateTime), N'url', 2, N'comment', 1, N'abc', N'abc', 2, 0, NULL, NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6079, N'Usmna', N'avadv', N'short', N'long', N'instal', CAST(0x0000ABF00138D3BC AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF00138D3BC AS DateTime), N'url', 2, N'comment', 1, N'abc', N'abc', 2, 0, N'name', N'url', 2, 0, 0, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6080, N'aakdjaksdj', N'ver', N'short', N'long', N'instal', CAST(0x0000ABF0013A25F4 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF0013A25F4 AS DateTime), N'url', 9, N'comment', 1, N'abc', N'abc', 2, 0, N'name', N'url', 2, 0, 0, CAST(0x0000ABF0013A25F4 AS DateTime), NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 5023, 3011)
INSERT [dbo].[Application] ([ApplicationID], [Name], [Ver], [ShortDescription], [LongDescription], [InstallationPath], [InstalledDate], [SupportPhone], [SupportEmail], [SupportAccountNo], [SupportExpirationDate], [SupportURL], [NumberOfLicenses], [Comment], [InstallerNameID], [Usrname], [Pass], [DeveloperTypeID], [DeveloperID], [CitrixApplicationName], [ApplicationURL], [ApplicationTypeID], [IsVisibleInsideGGP], [VProcessDependent], [CertificateExpiration], [SMTP], [IsVisibleNonEmployee], [FirewallException], [LDAP], [LastUpdatedBy], [LastUpdated], [SupportGroup], [ApplicationLocationURL], [Application_server], [Application_database]) VALUES (6081, N'lklklk', N'ver', N'short', N'long', N'instal', CAST(0x0000ABF0013B00A1 AS DateTime), N'phone', NULL, N'account', CAST(0x0000ABF0013B00A1 AS DateTime), N'url', 2, N'comment', 1, N'abc', N'abc', 2, 0, N'name', N'url', 2, 0, 0, CAST(0x0000ABF0013B00A1 AS DateTime), N'smpt', 0, N'firewal', N'ldap', NULL, NULL, NULL, NULL, 5023, 3011)
SET IDENTITY_INSERT [dbo].[Application] OFF
SET IDENTITY_INSERT [dbo].[ApplicationADGroup] ON 

INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (21, 6071, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (22, 6072, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (23, 6073, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (24, 6074, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (25, 6077, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (26, 6078, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (27, 6079, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (28, 6080, 1)
INSERT [dbo].[ApplicationADGroup] ([ApplicationADGroupID], [ApplicationID], [ADGroupID]) VALUES (29, 6081, 1)
SET IDENTITY_INSERT [dbo].[ApplicationADGroup] OFF
SET IDENTITY_INSERT [dbo].[ApplicationDatabase] ON 

INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1023, 6071, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1024, 6072, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1025, 6073, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1026, 6074, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1027, 6077, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1028, 6078, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1029, 6079, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1030, 6080, 3011)
INSERT [dbo].[ApplicationDatabase] ([ApplicationDatabaseID], [ApplicationID], [DatabaseID]) VALUES (1031, 6081, 3011)
SET IDENTITY_INSERT [dbo].[ApplicationDatabase] OFF
SET IDENTITY_INSERT [dbo].[ApplicationDocument] ON 

INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1023, 6071, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1024, 6072, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1025, 6073, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1026, 6074, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1027, 6077, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1028, 6078, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1029, 6079, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1030, 6080, 5)
INSERT [dbo].[ApplicationDocument] ([ApplicationDocumentID], [ApplicationID], [DocumentID]) VALUES (1031, 6081, 5)
SET IDENTITY_INSERT [dbo].[ApplicationDocument] OFF
SET IDENTITY_INSERT [dbo].[ApplicationLog] ON 

INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (1, N'lkpCountry', 25, CAST(0x0000AA1A012AD498 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (2, N'lkpCountry', 26, CAST(0x0000AA1A015740D3 AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (3, N'lkpCountry', 27, CAST(0x0000AA1A01574EB3 AS DateTime), N'0', N'United States Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (4, N'lkpCountry', 28, CAST(0x0000AA1A01575A42 AS DateTime), N'0', N'Canada Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (5, N'lkpCountry', 29, CAST(0x0000AA1B00C56316 AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (6, N'lkpCountry', 30, CAST(0x0000AA1B00C57929 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (7, N'lkpState', 14, CAST(0x0000AA1C0118C7A5 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (8, N'lkpCountry', 30, CAST(0x0000AA1C0118C7C1 AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (9, N'lkpCountry', 31, CAST(0x0000AA1D00C9901C AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (10, N'lkpState', 15, CAST(0x0000AA1D00C9A647 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (11, N'lkpState', 15, CAST(0x0000AA1D00E9B5F2 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (12, N'lkpCountry', 31, CAST(0x0000AA1D00E9B5F3 AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (13, N'lkpCountry', 32, CAST(0x0000AA1D00E04A22 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (14, N'lkpState', 16, CAST(0x0000AA1D00E07E13 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (15, N'lkpState', 17, CAST(0x0000AA1D00E47428 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (16, N'lkpState', 17, CAST(0x0000AA1D00E56665 AS DateTime), N'0', N'Sindh Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (17, N'lkpCity', 1, CAST(0x0000AA1D0110C7C1 AS DateTime), N'0', N'Leiah Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (18, N'lkpCity', 1, CAST(0x0000AA1D0141BA1F AS DateTime), N'0', N'Leiah Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (19, N'lkpCity', 2, CAST(0x0000AA1D014A24CC AS DateTime), N'0', N'Attock City Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (20, N'lkpState', 18, CAST(0x0000AA1D0156CD35 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (21, N'lkpState', 19, CAST(0x0000AA1D0156D85D AS DateTime), N'0', N'Khyber Pakhtunkhwa Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (22, N'lkpState', 20, CAST(0x0000AA1D0156E303 AS DateTime), N'0', N'Balochistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (23, N'lkpDataCenter', 1, CAST(0x0000AA1D015B6992 AS DateTime), NULL, N'Attock Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (24, N'lkpDataCenter', 2, CAST(0x0000AA1D015B8BB0 AS DateTime), N'0', N'Attock Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (25, N'lkpDataCenter', 1, CAST(0x0000AA1F014575F6 AS DateTime), N'0', N'Attock Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (26, N'lkpCity', 2, CAST(0x0000AA1F01457623 AS DateTime), N'0', N'Attock City Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (27, N'lkpState', 16, CAST(0x0000AA1F01457624 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (28, N'lkpCountry', 29, CAST(0x0000AA1F01457624 AS DateTime), N'0', N'India Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (29, N'lkpState', NULL, CAST(0x0000AA1F01457627 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (30, N'lkpCity', NULL, CAST(0x0000AA1F01457633 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (31, N'lkpDataCenter', NULL, CAST(0x0000AA1F01457634 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (32, N'lkpDepartment', NULL, CAST(0x0000AA1F01457641 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (33, N'lkpCountry', NULL, CAST(0x0000AA1F01457B6D AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (34, N'lkpState', NULL, CAST(0x0000AA1F01457B6E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (35, N'lkpCity', NULL, CAST(0x0000AA1F01457B6E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (36, N'lkpDataCenter', NULL, CAST(0x0000AA1F01457B6E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (37, N'lkpDepartment', NULL, CAST(0x0000AA1F01457B6E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (38, N'lkpCountry', 33, CAST(0x0000AA1F014A76C3 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (39, N'lkpState', 21, CAST(0x0000AA1F014A99B7 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (40, N'lkpState', 22, CAST(0x0000AA1F014AAAA2 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (41, N'lkpState', 21, CAST(0x0000AA1F014ADEEE AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (42, N'lkpCountry', 33, CAST(0x0000AA1F014ADEEF AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (43, N'lkpState', NULL, CAST(0x0000AA1F014ADEEF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (44, N'lkpCity', NULL, CAST(0x0000AA1F014ADEF8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (45, N'lkpDataCenter', NULL, CAST(0x0000AA1F014ADEF9 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (46, N'lkpDepartment', NULL, CAST(0x0000AA1F014ADEFA AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (47, N'lkpCountry', NULL, CAST(0x0000AA1F014AE05D AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (48, N'lkpState', NULL, CAST(0x0000AA1F014AE05E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (49, N'lkpCity', NULL, CAST(0x0000AA1F014AE05F AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (50, N'lkpDataCenter', NULL, CAST(0x0000AA1F014AE060 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (51, N'lkpDepartment', NULL, CAST(0x0000AA1F014AE060 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (52, N'lkpCountry', NULL, CAST(0x0000AA1F014AE117 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (53, N'lkpState', NULL, CAST(0x0000AA1F014AE118 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (54, N'lkpCity', NULL, CAST(0x0000AA1F014AE118 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (55, N'lkpDataCenter', NULL, CAST(0x0000AA1F014AE119 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (56, N'lkpDepartment', NULL, CAST(0x0000AA1F014AE12B AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (57, N'lkpCountry', NULL, CAST(0x0000AA1F01580B13 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (58, N'lkpState', NULL, CAST(0x0000AA1F01580B14 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (59, N'lkpCity', NULL, CAST(0x0000AA1F01580B15 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (60, N'lkpDataCenter', NULL, CAST(0x0000AA1F01580B16 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (61, N'lkpDepartment', NULL, CAST(0x0000AA1F01580B17 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (62, N'lkpCountry', NULL, CAST(0x0000AA1F01580BD1 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (63, N'lkpState', NULL, CAST(0x0000AA1F01580BD2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (64, N'lkpCity', NULL, CAST(0x0000AA1F01580BD2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (65, N'lkpDataCenter', NULL, CAST(0x0000AA1F01580BD3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (66, N'lkpDepartment', NULL, CAST(0x0000AA1F01580BD3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (67, N'lkpCountry', NULL, CAST(0x0000AA1F01580C01 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (68, N'lkpState', NULL, CAST(0x0000AA1F01580C02 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (69, N'lkpCity', NULL, CAST(0x0000AA1F01580C02 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (70, N'lkpDataCenter', NULL, CAST(0x0000AA1F01580C03 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (71, N'lkpDepartment', NULL, CAST(0x0000AA1F01580C03 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (72, N'lkpCountry', NULL, CAST(0x0000AA1F01580C34 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (73, N'lkpState', NULL, CAST(0x0000AA1F01580C34 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (74, N'lkpCity', NULL, CAST(0x0000AA1F01580C35 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (75, N'lkpDataCenter', NULL, CAST(0x0000AA1F01580C35 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (76, N'lkpDepartment', NULL, CAST(0x0000AA1F01580C35 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (77, N'lkpCountry', 34, CAST(0x0000AA1F01595DF9 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (78, N'lkpState', 23, CAST(0x0000AA1F01596E27 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (79, N'lkpState', 24, CAST(0x0000AA1F01596E71 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (80, N'lkpCity', 3, CAST(0x0000AA1F01596F3C AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (81, N'lkpCity', 4, CAST(0x0000AA1F01596F4E AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (82, N'lkpDataCenter', 3, CAST(0x0000AA1F015978B5 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (83, N'lkpDataCenter', 4, CAST(0x0000AA1F01597CA6 AS DateTime), N'0', N'Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (84, N'lkpDataCenter', 3, CAST(0x0000AA1F0159D04C AS DateTime), N'0', N'Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (85, N'lkpCity', 3, CAST(0x0000AA1F0159D04C AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (86, N'lkpState', 23, CAST(0x0000AA1F0159D04D AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (87, N'lkpCountry', 34, CAST(0x0000AA1F0159D04E AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (88, N'lkpState', NULL, CAST(0x0000AA1F0159D059 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (89, N'lkpCity', NULL, CAST(0x0000AA1F0159D059 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (90, N'lkpDataCenter', NULL, CAST(0x0000AA1F0159D059 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (91, N'lkpDepartment', NULL, CAST(0x0000AA1F0159D05B AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (92, N'lkpCountry', NULL, CAST(0x0000AA1F0159D157 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (93, N'lkpState', NULL, CAST(0x0000AA1F0159D158 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (94, N'lkpCity', NULL, CAST(0x0000AA1F0159D158 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (95, N'lkpDataCenter', NULL, CAST(0x0000AA1F0159D159 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (96, N'lkpDepartment', NULL, CAST(0x0000AA1F0159D15A AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (97, N'lkpCountry', NULL, CAST(0x0000AA1F015A90FF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (98, N'lkpState', NULL, CAST(0x0000AA1F015A9104 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (99, N'lkpCity', NULL, CAST(0x0000AA1F015A910B AS DateTime), NULL, NULL)
GO
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (100, N'lkpDataCenter', NULL, CAST(0x0000AA1F015A910D AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (101, N'lkpDepartment', NULL, CAST(0x0000AA1F015A910F AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (102, N'lkpCountry', NULL, CAST(0x0000AA1F015B8035 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (103, N'lkpState', NULL, CAST(0x0000AA1F015B8037 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (104, N'lkpCity', NULL, CAST(0x0000AA1F015B8038 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (105, N'lkpDataCenter', NULL, CAST(0x0000AA1F015B8039 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (106, N'lkpDepartment', NULL, CAST(0x0000AA1F015B803A AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (107, N'lkpCountry', 35, CAST(0x0000AA1F015BB704 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (108, N'lkpState', 25, CAST(0x0000AA1F015BB744 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (109, N'lkpState', 26, CAST(0x0000AA1F015BB74E AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (110, N'lkpState', 25, CAST(0x0000AA1F015C99A0 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (111, N'lkpCountry', 35, CAST(0x0000AA1F015C99A1 AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (112, N'lkpState', NULL, CAST(0x0000AA1F015C99A1 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (113, N'lkpCity', NULL, CAST(0x0000AA1F015C99A2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (114, N'lkpDataCenter', NULL, CAST(0x0000AA1F015C99A3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (115, N'lkpDepartment', NULL, CAST(0x0000AA1F015C99AF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (116, N'lkpCountry', NULL, CAST(0x0000AA1F015C9AB2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (117, N'lkpState', NULL, CAST(0x0000AA1F015C9AB3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (118, N'lkpCity', NULL, CAST(0x0000AA1F015C9AB4 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (119, N'lkpDataCenter', NULL, CAST(0x0000AA1F015C9AB4 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (120, N'lkpDepartment', NULL, CAST(0x0000AA1F015C9AB4 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (121, N'lkpCountry', 36, CAST(0x0000AA1F015D1809 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (122, N'lkpState', 27, CAST(0x0000AA1F015D1863 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (123, N'lkpState', 28, CAST(0x0000AA1F015D186B AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (124, N'lkpCity', 5, CAST(0x0000AA1F015D371A AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (125, N'lkpCity', 6, CAST(0x0000AA1F015D42D3 AS DateTime), N'0', N'Faisalabad Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (126, N'lkpDataCenter', 5, CAST(0x0000AA1F015D42E9 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (127, N'lkpDataCenter', 6, CAST(0x0000AA1F015D42EE AS DateTime), N'0', N'Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (128, N'lkpDepartment', 1, CAST(0x0000AA1F015D430D AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (129, N'lkpDepartment', 2, CAST(0x0000AA1F015D4313 AS DateTime), N'0', N'Dc1-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (130, N'lkpDepartment', 3, CAST(0x0000AA1F015D431D AS DateTime), N'0', N'Dc2-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (131, N'lkpDepartment', 4, CAST(0x0000AA1F015D4327 AS DateTime), N'0', N'Dc2-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (132, N'lkpDepartment', 5, CAST(0x0000AA1F015D432A AS DateTime), N'0', N'Dc2-3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (133, N'lkpDataCenter', 7, CAST(0x0000AA1F015D4332 AS DateTime), N'0', N'Dc3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (134, N'lkpDepartment', 6, CAST(0x0000AA1F015D4338 AS DateTime), N'0', N'Dc3-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (135, N'lkpDepartment', 7, CAST(0x0000AA1F015D433E AS DateTime), N'0', N'Dc3-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (136, N'lkpCity', 7, CAST(0x0000AA1F015D434A AS DateTime), N'0', N'Karachi Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (137, N'lkpDataCenter', 8, CAST(0x0000AA1F015D4352 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (138, N'lkpDepartment', 8, CAST(0x0000AA1F015D435B AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (139, N'lkpDepartment', 1, CAST(0x0000AA1F015DB68C AS DateTime), N'0', N'Dc1-1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (140, N'lkpDataCenter', 5, CAST(0x0000AA1F015DB68D AS DateTime), N'0', N'Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (141, N'lkpCity', 5, CAST(0x0000AA1F015DB68D AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (142, N'lkpState', 27, CAST(0x0000AA1F015DB68E AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (143, N'lkpCountry', 36, CAST(0x0000AA1F015DB698 AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (144, N'lkpState', NULL, CAST(0x0000AA1F015DB69A AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (145, N'lkpCity', NULL, CAST(0x0000AA1F015DB69B AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (146, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DB69C AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (147, N'lkpDepartment', NULL, CAST(0x0000AA1F015DB69E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (148, N'lkpCountry', NULL, CAST(0x0000AA1F015DB79E AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (149, N'lkpState', NULL, CAST(0x0000AA1F015DB7A0 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (150, N'lkpCity', NULL, CAST(0x0000AA1F015DB7B1 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (151, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DB7B2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (152, N'lkpDepartment', NULL, CAST(0x0000AA1F015DB7B3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (153, N'lkpCountry', NULL, CAST(0x0000AA1F015DB8B2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (154, N'lkpState', NULL, CAST(0x0000AA1F015DB8B3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (155, N'lkpCity', NULL, CAST(0x0000AA1F015DB8B4 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (156, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DB8B5 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (157, N'lkpDepartment', NULL, CAST(0x0000AA1F015DB8B6 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (158, N'lkpCountry', NULL, CAST(0x0000AA1F015DB9E8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (159, N'lkpState', NULL, CAST(0x0000AA1F015DB9EA AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (160, N'lkpCity', NULL, CAST(0x0000AA1F015DB9EC AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (161, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DB9EE AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (162, N'lkpDepartment', NULL, CAST(0x0000AA1F015DB9EF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (163, N'lkpCountry', NULL, CAST(0x0000AA1F015DBAE7 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (164, N'lkpState', NULL, CAST(0x0000AA1F015DBAE8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (165, N'lkpCity', NULL, CAST(0x0000AA1F015DBAE8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (166, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DBAE8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (167, N'lkpDepartment', NULL, CAST(0x0000AA1F015DBAE9 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (168, N'lkpCountry', NULL, CAST(0x0000AA1F015DBBB8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (169, N'lkpState', NULL, CAST(0x0000AA1F015DBBB9 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (170, N'lkpCity', NULL, CAST(0x0000AA1F015DBBBB AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (171, N'lkpDataCenter', NULL, CAST(0x0000AA1F015DBBBB AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (172, N'lkpDepartment', NULL, CAST(0x0000AA1F015DBBCD AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (173, N'lkpCountry', NULL, CAST(0x0000AA1F015EBEBA AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (174, N'lkpState', NULL, CAST(0x0000AA1F015EBEC2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (175, N'lkpCity', NULL, CAST(0x0000AA1F015EBED3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (176, N'lkpDataCenter', NULL, CAST(0x0000AA1F015EBEDD AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (177, N'lkpDepartment', NULL, CAST(0x0000AA1F015EBEE8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (178, N'lkpCountry', 37, CAST(0x0000AA1F015EE821 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (179, N'lkpCountry', 38, CAST(0x0000AA1F015EE829 AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (180, N'lkpState', 29, CAST(0x0000AA1F015EE834 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (181, N'lkpState', 30, CAST(0x0000AA1F015EE83C AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (182, N'lkpCity', 8, CAST(0x0000AA1F015EE84D AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (183, N'lkpCity', 9, CAST(0x0000AA1F015EE854 AS DateTime), N'0', N'Faisalabad Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (184, N'lkpDataCenter', 9, CAST(0x0000AA1F015EE85C AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (185, N'lkpDataCenter', 10, CAST(0x0000AA1F015EE860 AS DateTime), N'0', N'Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (186, N'lkpDepartment', 9, CAST(0x0000AA1F015EE869 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (187, N'lkpDepartment', 10, CAST(0x0000AA1F015EE86F AS DateTime), N'0', N'Dc1-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (188, N'lkpDepartment', 11, CAST(0x0000AA1F015EE875 AS DateTime), N'0', N'Dc2-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (189, N'lkpDepartment', 12, CAST(0x0000AA1F015EE878 AS DateTime), N'0', N'Dc2-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (190, N'lkpDepartment', 13, CAST(0x0000AA1F015EE87B AS DateTime), N'0', N'Dc2-3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (191, N'lkpDataCenter', 11, CAST(0x0000AA1F015EE888 AS DateTime), N'0', N'Dc3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (192, N'lkpDepartment', 14, CAST(0x0000AA1F015EE899 AS DateTime), N'0', N'Dc3-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (193, N'lkpDepartment', 15, CAST(0x0000AA1F015EE8AB AS DateTime), N'0', N'Dc3-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (194, N'lkpCity', 10, CAST(0x0000AA1F015EE8BF AS DateTime), N'0', N'Karachi Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (195, N'lkpDataCenter', 12, CAST(0x0000AA1F015EE8C7 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (196, N'lkpDepartment', 16, CAST(0x0000AA1F015EE8D2 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (197, N'lkpState', 31, CAST(0x0000AA1F015EE8DF AS DateTime), N'0', N'Maharashtra Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (198, N'lkpCity', 11, CAST(0x0000AA1F015EE8FC AS DateTime), N'0', N'Mumbai Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (199, N'lkpDataCenter', 13, CAST(0x0000AA1F015EE906 AS DateTime), N'0', N'Data Center Mumbai Inserted')
GO
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (200, N'lkpDepartment', 17, CAST(0x0000AA1F015EE90E AS DateTime), N'0', N'Department 1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (201, N'lkpDepartment', 18, CAST(0x0000AA1F015EE916 AS DateTime), N'0', N'Department 2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (202, N'lkpDepartment', 19, CAST(0x0000AA1F015EE91F AS DateTime), N'0', N'Department 3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (203, N'lkpDepartment', 20, CAST(0x0000AA1F015EE927 AS DateTime), N'0', N'Department 4 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (204, N'lkpDepartment', 9, CAST(0x0000AA1F015F3045 AS DateTime), N'0', N'Dc1-1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (205, N'lkpDataCenter', 9, CAST(0x0000AA1F015F3046 AS DateTime), N'0', N'Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (206, N'lkpCity', 8, CAST(0x0000AA1F015F3047 AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (207, N'lkpState', 29, CAST(0x0000AA1F015F3047 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (208, N'lkpCountry', 38, CAST(0x0000AA1F015F3048 AS DateTime), N'0', N'India Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (209, N'lkpState', NULL, CAST(0x0000AA1F015F3048 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (210, N'lkpCity', NULL, CAST(0x0000AA1F015F3049 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (211, N'lkpDataCenter', NULL, CAST(0x0000AA1F015F3049 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (212, N'lkpDepartment', NULL, CAST(0x0000AA1F015F3049 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (213, N'lkpCountry', NULL, CAST(0x0000AA1F015F3170 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (214, N'lkpState', NULL, CAST(0x0000AA1F015F3174 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (215, N'lkpCity', NULL, CAST(0x0000AA1F015F3178 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (216, N'lkpDataCenter', NULL, CAST(0x0000AA1F015F317A AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (217, N'lkpDepartment', NULL, CAST(0x0000AA1F015F317B AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (218, N'lkpCountry', NULL, CAST(0x0000AA1F015F31EF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (219, N'lkpState', NULL, CAST(0x0000AA1F015F31F6 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (220, N'lkpCity', NULL, CAST(0x0000AA1F015F31F7 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (221, N'lkpDataCenter', NULL, CAST(0x0000AA1F015F31F8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (222, N'lkpDepartment', NULL, CAST(0x0000AA1F015F31F9 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (223, N'lkpCountry', 39, CAST(0x0000AA1F015F5EF3 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (224, N'lkpCountry', 40, CAST(0x0000AA1F015F5F07 AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (225, N'lkpState', 32, CAST(0x0000AA1F015F5F13 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (226, N'lkpState', 33, CAST(0x0000AA1F015F5F2E AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (227, N'lkpCity', 12, CAST(0x0000AA1F015F5F5C AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (228, N'lkpCity', 13, CAST(0x0000AA1F015F5F83 AS DateTime), N'0', N'Faisalabad Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (229, N'lkpDataCenter', 14, CAST(0x0000AA1F015F74D3 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (230, N'lkpDataCenter', 15, CAST(0x0000AA1F015F79C8 AS DateTime), N'0', N'Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (231, N'lkpDepartment', 21, CAST(0x0000AA1F015F79D1 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (232, N'lkpDepartment', 22, CAST(0x0000AA1F015F79D5 AS DateTime), N'0', N'Dc1-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (233, N'lkpDepartment', 23, CAST(0x0000AA1F015F79DA AS DateTime), N'0', N'Dc2-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (234, N'lkpDepartment', 24, CAST(0x0000AA1F015F79DF AS DateTime), N'0', N'Dc2-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (235, N'lkpDepartment', 25, CAST(0x0000AA1F015F79E2 AS DateTime), N'0', N'Dc2-3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (236, N'lkpDataCenter', 16, CAST(0x0000AA1F015F7AF0 AS DateTime), N'0', N'Dc3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (237, N'lkpDepartment', 26, CAST(0x0000AA1F015F7AFF AS DateTime), N'0', N'Dc3-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (238, N'lkpDepartment', 27, CAST(0x0000AA1F015F7B02 AS DateTime), N'0', N'Dc3-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (239, N'lkpCity', 14, CAST(0x0000AA1F015F7B13 AS DateTime), N'0', N'Karachi Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (240, N'lkpDataCenter', 17, CAST(0x0000AA1F015F7B9C AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (241, N'lkpDepartment', 28, CAST(0x0000AA1F015F7BA3 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (242, N'lkpState', 34, CAST(0x0000AA1F015F7BAC AS DateTime), N'0', N'Maharashtra Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (243, N'lkpCity', 15, CAST(0x0000AA1F015F7BB6 AS DateTime), N'0', N'Mumbai Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (244, N'lkpDataCenter', 18, CAST(0x0000AA1F015F7BE6 AS DateTime), N'0', N'Data Center Mumbai Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (245, N'lkpDepartment', 29, CAST(0x0000AA1F015F7BEB AS DateTime), N'0', N'Department 1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (246, N'lkpDepartment', 30, CAST(0x0000AA1F015F7BEE AS DateTime), N'0', N'Department 2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (247, N'lkpDepartment', 31, CAST(0x0000AA1F015F7BF3 AS DateTime), N'0', N'Department 3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (248, N'lkpDepartment', 32, CAST(0x0000AA1F015F7BF9 AS DateTime), N'0', N'Department 4 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (249, N'lkpDepartment', 21, CAST(0x0000AA1F01666E51 AS DateTime), N'0', N'Dc1-1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (250, N'lkpDataCenter', 14, CAST(0x0000AA1F01666E52 AS DateTime), N'0', N'Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (251, N'lkpCity', 12, CAST(0x0000AA1F01666E54 AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (252, N'lkpState', 32, CAST(0x0000AA1F01666E54 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (253, N'lkpCountry', 40, CAST(0x0000AA1F01666E55 AS DateTime), N'0', N'India Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (254, N'lkpState', NULL, CAST(0x0000AA1F01666E56 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (255, N'lkpCity', NULL, CAST(0x0000AA1F01666E56 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (256, N'lkpDataCenter', NULL, CAST(0x0000AA1F01666E56 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (257, N'lkpDepartment', NULL, CAST(0x0000AA1F01666E56 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (258, N'lkpCountry', NULL, CAST(0x0000AA1F016673CD AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (259, N'lkpState', NULL, CAST(0x0000AA1F016673CE AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (260, N'lkpCity', NULL, CAST(0x0000AA1F016673CE AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (261, N'lkpDataCenter', NULL, CAST(0x0000AA1F016673CF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (262, N'lkpDepartment', NULL, CAST(0x0000AA1F016673CF AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (263, N'lkpCountry', NULL, CAST(0x0000AA1F0166CAE3 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (264, N'lkpState', NULL, CAST(0x0000AA1F0166CAE4 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (265, N'lkpCity', NULL, CAST(0x0000AA1F0166CAE5 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (266, N'lkpDataCenter', NULL, CAST(0x0000AA1F0166CAE7 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (267, N'lkpDepartment', NULL, CAST(0x0000AA1F0166CAE8 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (268, N'lkpCountry', 41, CAST(0x0000AA1F0167F248 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (269, N'lkpCountry', 42, CAST(0x0000AA1F0167F24A AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (270, N'lkpState', 35, CAST(0x0000AA1F0167F253 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (271, N'lkpState', 36, CAST(0x0000AA1F0167F257 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (272, N'lkpCity', 16, CAST(0x0000AA1F0167F268 AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (273, N'lkpCity', 17, CAST(0x0000AA1F0167F26E AS DateTime), N'0', N'Faisalabad Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (274, N'lkpDataCenter', 19, CAST(0x0000AA1F0167F843 AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (275, N'lkpDataCenter', 20, CAST(0x0000AA1F0167F84A AS DateTime), N'0', N'Dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (276, N'lkpDepartment', 33, CAST(0x0000AA1F0167F865 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (277, N'lkpDepartment', 34, CAST(0x0000AA1F0167F86B AS DateTime), N'0', N'Dc1-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (278, N'lkpDepartment', 35, CAST(0x0000AA1F0167F874 AS DateTime), N'0', N'Dc2-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (279, N'lkpDepartment', 36, CAST(0x0000AA1F0167F890 AS DateTime), N'0', N'Dc2-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (280, N'lkpDepartment', 37, CAST(0x0000AA1F0167F89B AS DateTime), N'0', N'Dc2-3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (281, N'lkpDataCenter', 21, CAST(0x0000AA1F0167F8A7 AS DateTime), N'0', N'Dc3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (282, N'lkpDepartment', 38, CAST(0x0000AA1F0167F8AF AS DateTime), N'0', N'Dc3-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (283, N'lkpDepartment', 39, CAST(0x0000AA1F0167F8B5 AS DateTime), N'0', N'Dc3-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (284, N'lkpCity', 18, CAST(0x0000AA1F0167F8C2 AS DateTime), N'0', N'Karachi Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (285, N'lkpDataCenter', 22, CAST(0x0000AA1F0167F8CA AS DateTime), N'0', N'Dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (286, N'lkpDepartment', 40, CAST(0x0000AA1F0167F8D4 AS DateTime), N'0', N'Dc1-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (287, N'lkpState', 37, CAST(0x0000AA1F0167F8DE AS DateTime), N'0', N'Maharashtra Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (288, N'lkpCity', 19, CAST(0x0000AA1F0167F8EC AS DateTime), N'0', N'Mumbai Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (289, N'lkpDataCenter', 23, CAST(0x0000AA1F0167F8F2 AS DateTime), N'0', N'Data Center Mumbai Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (290, N'lkpDepartment', 41, CAST(0x0000AA1F0167F8FA AS DateTime), N'0', N'Department 1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (291, N'lkpDepartment', 42, CAST(0x0000AA1F0167F8FE AS DateTime), N'0', N'Department 2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (292, N'lkpDepartment', 43, CAST(0x0000AA1F0167F902 AS DateTime), N'0', N'Department 3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (293, N'lkpDepartment', 44, CAST(0x0000AA1F0167F907 AS DateTime), N'0', N'Department 4 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (294, N'lkpDataCenter', 22, CAST(0x0000AA230111E1BE AS DateTime), N'0', N'Dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (295, N'lkpDepartment', 41, CAST(0x0000AA230111EEE0 AS DateTime), N'0', N'Department 1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (296, N'lkpDataCenter', 23, CAST(0x0000AA230111EEE0 AS DateTime), N'0', N'Data Center Mumbai Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (297, N'lkpCountry', 43, CAST(0x0000AA2500ECC09A AS DateTime), N'0', N'Canada Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (298, N'lkpDepartment', 33, CAST(0x0000AA2500ECDFBF AS DateTime), N'0', N'Dc1-1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (299, N'lkpDataCenter', 19, CAST(0x0000AA2500ECDFCA AS DateTime), N'0', N'Dc1 Deleted')
GO
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (300, N'lkpCity', 16, CAST(0x0000AA2500ECDFDA AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (301, N'lkpState', 35, CAST(0x0000AA2500ECE008 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (302, N'lkpCountry', 41, CAST(0x0000AA2500ECE02B AS DateTime), N'0', N'Pakistan Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (303, N'lkpCountry', 44, CAST(0x0000AA2500ECF3A6 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (304, N'lkpDataCenter', 24, CAST(0x0000AA3901510A2B AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (305, N'lkpDataCenter', 24, CAST(0x0000AA390151429C AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (306, N'lkpDataCenter', 25, CAST(0x0000AA390152D96A AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (307, N'lkpDataCenter', 25, CAST(0x0000AA390152EACC AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (308, N'lkpDataCenter', 26, CAST(0x0000AA3901546F25 AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (309, N'lkpDataCenter', 26, CAST(0x0000AA39015608BF AS DateTime), N'0', NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (310, N'lkpDataCenter', 27, CAST(0x0000AA39015622BE AS DateTime), N'0', N'mumbai-dc1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (311, N'lkpDataCenter', 28, CAST(0x0000AA390156345C AS DateTime), N'0', N'mumbai-dc2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (312, N'lkpDepartment', 45, CAST(0x0000AA39015677FC AS DateTime), N'0', N'Department 1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (313, N'lkpDepartment', 46, CAST(0x0000AA390156821D AS DateTime), N'0', N'Department2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (314, N'lkpDepartment', 47, CAST(0x0000AA3901568BD2 AS DateTime), N'0', N'Department3 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (315, N'lkpDepartment', 48, CAST(0x0000AA39015694C9 AS DateTime), N'0', N'Department4 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (316, N'lkpCountry', 45, CAST(0x0000AA5500F010C8 AS DateTime), N'0', N'Indonesia Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (317, N'lkpCountry', 43, CAST(0x0000AA5500F03BD3 AS DateTime), N'0', N'Canada Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (318, N'lkpCountry', 45, CAST(0x0000AA5500F0464B AS DateTime), N'0', N'Indonesia Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (319, N'lkpState', 38, CAST(0x0000AA550116AED3 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (320, N'lkpCity', 20, CAST(0x0000AA55011913FA AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (321, N'lkpDepartment', 45, CAST(0x0000AA5501192C2B AS DateTime), N'0', N'Department 1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (322, N'lkpDataCenter', 27, CAST(0x0000AA5501192C2F AS DateTime), N'0', N'mumbai-dc1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (323, N'lkpCity', 19, CAST(0x0000AA5501192C30 AS DateTime), N'0', N'Mumbai Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (324, N'lkpDataCenter', 29, CAST(0x0000AA5501195B60 AS DateTime), N'0', N'lr1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (325, N'lkpCity', 21, CAST(0x0000AA550119A6DE AS DateTime), N'0', N'Faisalabad Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (326, N'lkpDataCenter', 30, CAST(0x0000AA550119CD48 AS DateTime), N'0', N'lr1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (327, N'lkpDepartment', 49, CAST(0x0000AA55011A59AD AS DateTime), N'0', N'QA Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (328, N'lkpDepartment', 50, CAST(0x0000AA55011A7F16 AS DateTime), N'0', N'QA Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (329, N'lkpDepartment', 51, CAST(0x0000AA700152F129 AS DateTime), N'0', N'QA Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (330, N'lkpDepartment', 52, CAST(0x0000AA700152F186 AS DateTime), N'0', N'QA1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (331, N'lkpDepartment', 53, CAST(0x0000AA7001531DD0 AS DateTime), N'0', N'QA Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (332, N'lkpDepartment', 54, CAST(0x0000AA7001531DDD AS DateTime), N'0', N'QA1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (333, N'lkpState', 39, CAST(0x0000AB6B00DC54DF AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (334, N'lkpDataCenter', 31, CAST(0x0000ABA901426C5D AS DateTime), N'0', N'lr2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (335, N'lkpDepartment', 49, CAST(0x0000ABAB00C68BAD AS DateTime), N'0', N'QA Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (336, N'lkpDataCenter', 29, CAST(0x0000ABAB00C68BAD AS DateTime), N'0', N'lr1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (337, N'lkpCity', 20, CAST(0x0000ABAB00C68BAE AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (338, N'lkpState', 37, CAST(0x0000ABAB00C68BAE AS DateTime), N'0', N'Maharashtra Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (339, N'lkpCountry', 42, CAST(0x0000ABAB00C68BAF AS DateTime), N'0', N'India Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (340, N'lkpState', NULL, CAST(0x0000ABAB00C69C40 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (341, N'lkpCity', NULL, CAST(0x0000ABAB00C6ABE2 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (342, N'lkpDataCenter', NULL, CAST(0x0000ABAB00C6C08A AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (343, N'lkpDepartment', NULL, CAST(0x0000ABAB00C71280 AS DateTime), NULL, NULL)
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (344, N'lkpCountry', 45, CAST(0x0000ABAB00C83E97 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (345, N'lkpState', 40, CAST(0x0000ABAB00C8510B AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (346, N'lkpCity', 22, CAST(0x0000ABAB00C864ED AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (347, N'lkpDataCenter', 32, CAST(0x0000ABAB00C87D23 AS DateTime), N'0', N'lr-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (348, N'lkpDepartment', 55, CAST(0x0000ABAB00C89B41 AS DateTime), N'0', N'QA-32 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (349, N'lkpCountry', 46, CAST(0x0000ABAB01142098 AS DateTime), N'0', N'India Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (350, N'lkpState', 41, CAST(0x0000ABAB01151776 AS DateTime), N'0', N'Sindh Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (351, N'lkpCity', 23, CAST(0x0000ABAB01152F24 AS DateTime), N'0', N'Karachi Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (352, N'lkpDataCenter', 33, CAST(0x0000ABAB01155C1C AS DateTime), N'0', N'kr-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (353, N'lkpDepartment', 56, CAST(0x0000ABAB01158F26 AS DateTime), N'0', N'kq-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (354, N'lkpDepartment', 57, CAST(0x0000ABAB0115DA6E AS DateTime), N'0', N'kq-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (355, N'lkpDataCenter', 34, CAST(0x0000ABAB0115FD01 AS DateTime), N'0', N'lr-2 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (356, N'lkpCountry', 47, CAST(0x0000ABAC011A7FE7 AS DateTime), N'0', N'United States Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (357, N'lkpCountry', 47, CAST(0x0000ABAC011BBE48 AS DateTime), N'0', N'United States Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (358, N'lkpCountry', 48, CAST(0x0000ABAC011BDE3C AS DateTime), N'0', N'United States Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (359, N'lkpCountry', 48, CAST(0x0000ABAC0122C299 AS DateTime), N'0', N'United States Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (360, N'lkpCountry', 49, CAST(0x0000ABAC01234936 AS DateTime), N'0', N'United States Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (361, N'lkpDepartment', 55, CAST(0x0000ABAC0125BB80 AS DateTime), N'0', N'QA-32 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (362, N'lkpDataCenter', 32, CAST(0x0000ABAC0125BB80 AS DateTime), N'0', N'lr-1 Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (363, N'lkpCity', 22, CAST(0x0000ABAC0125BB84 AS DateTime), N'0', N'Lahore Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (364, N'lkpState', 40, CAST(0x0000ABAC0125BB84 AS DateTime), N'0', N'Punjab Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (365, N'lkpCountry', 46, CAST(0x0000ABAC0125BB84 AS DateTime), N'0', N'India Deleted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (366, N'lkpCountry', 50, CAST(0x0000ABAE0124157F AS DateTime), N'0', N'Canada Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (367, N'lkpCountry', 51, CAST(0x0000ABAE0124347F AS DateTime), N'0', N'United States Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (368, N'lkpState', 42, CAST(0x0000ABAE012509EB AS DateTime), N'0', N'Newfoundland And Labrador Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (369, N'lkpCountry', 52, CAST(0x0000ABF0011136B9 AS DateTime), N'0', N'Pakistan Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (370, N'lkpState', 43, CAST(0x0000ABF001115247 AS DateTime), N'0', N'Punjab Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (371, N'lkpCity', 1, CAST(0x0000ABF001116B51 AS DateTime), N'0', N'Lahore Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (372, N'lkpDataCenter', 1, CAST(0x0000ABF001118685 AS DateTime), N'0', N'dh-1 Inserted')
INSERT [dbo].[ApplicationLog] ([ApplicationLogId], [TableName], [PrimaryKeyId], [TransactionTime], [UserName], [LogText]) VALUES (373, N'lkpDepartment', 1, CAST(0x0000ABF00111A771 AS DateTime), N'0', N'qa-1 Inserted')
SET IDENTITY_INSERT [dbo].[ApplicationLog] OFF
SET IDENTITY_INSERT [dbo].[AspNetCompany] ON 

INSERT [dbo].[AspNetCompany] ([CompanyId], [CompanyName], [AllowedModules], [IsActive]) VALUES (1, N'Coder INN', N'dADI', 1)
INSERT [dbo].[AspNetCompany] ([CompanyId], [CompanyName], [AllowedModules], [IsActive]) VALUES (2, N'Coder Inn', N'dADI', 1)
INSERT [dbo].[AspNetCompany] ([CompanyId], [CompanyName], [AllowedModules], [IsActive]) VALUES (3, N'test', N'dASP', 1)
INSERT [dbo].[AspNetCompany] ([CompanyId], [CompanyName], [AllowedModules], [IsActive]) VALUES (4, N'softpro', N'dADI', 1)
INSERT [dbo].[AspNetCompany] ([CompanyId], [CompanyName], [AllowedModules], [IsActive]) VALUES (5, N'codestyle', N'dADI,dASP,dARA', 1)
SET IDENTITY_INSERT [dbo].[AspNetCompany] OFF
INSERT [dbo].[AspNetRoles] ([Id], [ConcurrencyStamp], [Name], [NormalizedName]) VALUES (N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a', N'b4c0a9e2-91fa-41e9-8b3e-c6756dda6729', N'Application', N'APPLICATION')
INSERT [dbo].[AspNetRoles] ([Id], [ConcurrencyStamp], [Name], [NormalizedName]) VALUES (N'35ab554e-fe81-479c-b9f6-ace8dd18bd82', N'784c7b72-4084-498b-82cc-12859f3e96e6', N'Admin', N'ADMIN')
INSERT [dbo].[AspNetRoles] ([Id], [ConcurrencyStamp], [Name], [NormalizedName]) VALUES (N'42f0670d-72be-4358-874d-01de9348a3c1', N'3b8edfae-c95c-4156-8404-0889f32ac2fa', N'Country', N'COUNTRY')
INSERT [dbo].[AspNetRoles] ([Id], [ConcurrencyStamp], [Name], [NormalizedName]) VALUES (N'4bd27868-9b8f-43e4-9fda-ae054d40c248', N'5440ee90-493a-4688-84c6-9192659a04a6', N'DataCenter', N'DATACENTER')
INSERT [dbo].[AspNetRoles] ([Id], [ConcurrencyStamp], [Name], [NormalizedName]) VALUES (N'f305db4d-7c00-4ef2-a7b3-11f6f4eb6510', N'7f987036-bfc0-490b-b547-c0b892cb4412', N'Department', N'DEPARTMENT')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'29485255-4e11-4ef1-aa8e-ff274be94683', N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'2ef76e02-0413-4111-b494-3f67b30332be', N'35ab554e-fe81-479c-b9f6-ace8dd18bd82')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'3492118b-323c-4ce1-afec-b5324af11a69', N'42f0670d-72be-4358-874d-01de9348a3c1')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'6d4cd179-0231-48af-82b1-025738b7ee70', N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'71e69810-8e75-4ca3-bac9-c214691509ff', N'35ab554e-fe81-479c-b9f6-ace8dd18bd82')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'8252b2ac-e205-4c52-a054-dd5e1048091b', N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'a7791adc-580b-49a0-a500-fa4136d2bab8', N'4bd27868-9b8f-43e4-9fda-ae054d40c248')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'e8fb14bc-cff9-4d9b-a6f7-d5b1defafcaf', N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a')
INSERT [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (N'ec1624d9-b40c-4e82-af03-0c49acfa6ac5', N'217d7b44-6c9f-4d35-89c0-f0b41ddd1e8a')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'29485255-4e11-4ef1-aa8e-ff274be94683', 0, N'ce430ec8-ff99-4f8c-96fa-cec45b0c4e23', N'c@c.com', 1, 1, NULL, N'C@C.COM', N'NADIR', N'AQAAAAEAACcQAAAAEGOjEpyigdVwYgE/J4RVveW4a2jcHNQmg3Lt/F2MurEDk3bUaCh29G9yeU9mnt14yw==', NULL, 0, N'79755d17-7673-46a4-bc39-7ac58585fd3e', 0, N'nadir', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'2ef76e02-0413-4111-b494-3f67b30332be', 0, N'a3d2a4c0-55ac-4a1e-b507-36f4437336c3', N'waqarkhan2002@gmail.com', 1, 1, NULL, N'WAQARKHAN2002@GMAIL.COM', N'WAQARKHAN2002@GMAIL.COM', N'AQAAAAEAACcQAAAAEH3zrXvadCgr01Icz1KfpB+21iPCQgKzkchSjGx0D6JkgoKCB0Ue32TF9JkbD9M0/w==', NULL, 0, N'a5002d3c-338f-4ebd-9a66-0f2bab91a8f1', 0, N'waqarkhan2002@gmail.com', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'303f2b6e-fb2b-4454-b3ab-09d715d1b695', 0, N'4547b163-8d8b-4e96-9f61-e0fdfab0f15b', N'ranabilal1994@gmail.com', 0, 1, NULL, N'RANABILAL1994@GMAIL.COM', N'RANABILAL1994@GMAIL.COM', N'AQAAAAEAACcQAAAAEJcQIpmwkjm3D3S7TBBCpNJ3xbAY3tCuThFnWJtUZvoZDJ8mA1PD0VLsuHq3Vf8HFA==', NULL, 0, N'6db75bdc-c859-4614-9fb0-53e33dbb439e', 0, N'ranabilal1994@gmail.com', 5, N'codestyle')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'3492118b-323c-4ce1-afec-b5324af11a69', 0, N'e330ae27-1ccc-4eb9-a155-944d5bad83b3', N't@t.com', 1, 1, NULL, N'T@T.COM', N'ASK', N'AQAAAAEAACcQAAAAEHzEkxmGSYBs8GNW8oMFPoBZZJVSkFfBt7xjITGYjjzCT6eMhzNW3/9wU9elLptQvw==', NULL, 0, N'b4a0f630-e4e5-40e9-a95b-3ba5e04049f3', 0, N'ask', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'657dfc22-7b2a-4278-a52e-aba3b49e49e1', 0, N'06f5f5c6-f853-4a70-a0c4-21dd1b717c31', N'ur@u.com', 1, 1, NULL, N'UR@U.COM', N'MARD', N'AQAAAAEAACcQAAAAEBPjVW2VFOnlxqvZ3w/AD1Gr/G/51ovE2WwJUqmui7lDpLYuYSVdq3qSOKGKA0ALmw==', NULL, 0, N'5be91757-5a3b-4407-828b-8bbdce14b4fa', 0, N'mard', 4, N'softpro')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'6d4cd179-0231-48af-82b1-025738b7ee70', 0, N'dd35ec43-fbc5-4022-b13f-7bc38229bde0', N'masoom@c.com', 1, 1, NULL, N'MASOOM@C.COM', N'MASOOM', N'AQAAAAEAACcQAAAAEAD9qeuWDWkossrrQWLVbC/TFrmI/UeW0Z2lpK9cfTi5oWCec8W1mgnL9X/WHW5ERA==', NULL, 0, N'0d5070f6-0a71-4b15-a2e0-cd12326d664b', 0, N'masoom', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'71e69810-8e75-4ca3-bac9-c214691509ff', 0, N'66eae5c5-4197-495a-83d6-27fd9a988f6c', N'nad@nad.com', 1, 1, NULL, N'NAD@NAD.COM', N'NAD', N'AQAAAAEAACcQAAAAEGmG2Jp241Z6zsi22MsMbvXjr1h4arnUVHFRz19D9Sh3A4bFe2zNYdBO/cGAZ0i3Iw==', NULL, 0, N'246754e2-5c2b-43e5-9c32-e0614231cb3d', 0, N'nad', 4, N'softpro')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'80cf2642-732d-4cc7-b06b-6c95db398bdc', 0, N'ef0d63fe-7810-4924-b321-02b59eca900a', N'2ndname@test.com', 1, 1, NULL, N'2NDNAME@TEST.COM', N'2NDNAME', N'AQAAAAEAACcQAAAAEG8igEjFpQiXh5kHbVXc6WJ7u6sYLS34JBHxLGhZEMBXJE0Qc5LTlPu3jjtKq6awEg==', NULL, 0, N'9e671e42-4ad1-47e2-9fba-220b24cec600', 0, N'2ndname', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'8252b2ac-e205-4c52-a054-dd5e1048091b', 0, N'050a5cd5-365e-4b8d-8ee6-e2fd29c50719', N'a@c.com', 1, 1, NULL, N'A@C.COM', N'AB', N'AQAAAAEAACcQAAAAEGjQjWloWjRcf4hctHD6pYHfybd3yeKLfmI03HQ5HjWJbsZi53IytWr+ktQejD5qEg==', NULL, 0, N'ca73cb89-4f16-475f-8bc0-bd827564183e', 0, N'ab', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'a0160b22-c758-46f9-8b4d-eec5c13a6742', 0, N'cec8ed0b-72d6-4a99-a731-e19bedf82ff3', N'Masoomfarishta6@hotmail.com', 0, 1, NULL, N'MASOOMFARISHTA6@HOTMAIL.COM', N'MASOOMFARISHTA6@HOTMAIL.COM', N'AQAAAAEAACcQAAAAEACc92UjvMyBlLJ1lvEJJHtlqYmREfUkXw5baeUvmWyMh1QI8XHa7KWJjnUn2a7T7A==', NULL, 0, N'9b97646d-fee8-4e7c-adbd-9ed165f8b398', 0, N'Masoomfarishta6@hotmail.com', 3, N'test')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'a7791adc-580b-49a0-a500-fa4136d2bab8', 0, N'0187dcb6-be11-460d-84ca-b0e69280b92b', N't@g.com', 1, 1, NULL, N'T@G.COM', N'GM', N'AQAAAAEAACcQAAAAEFcRqTu8pkK51ecwq2PGiKSfDdv5eH9WSUObk6nLV5sddIXC8z4I86i1bUhVlH7p1Q==', NULL, 0, N'afdbb761-b376-480a-ba9b-d934897c2ec5', 0, N'gm', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'e4ad50e9-9242-46b7-b68b-0f545528370f', 0, N'ff493e69-609f-4c4d-87a7-79ebcb591c89', N'takhayultech@gmail.com', 1, 1, NULL, N'TAKHAYULTECH@GMAIL.COM', N'TAKHAYULTECH@GMAIL.COM', N'AQAAAAEAACcQAAAAEK8FjKoPel3bitxsmYl3S352lwbz/4P7x+pt+tGEK4vgYB4Chzzx9oSN8sw/ql6HLg==', NULL, 0, N'af2c37ae-2a3c-44d8-b850-05767641aedc', 0, N'takhayultech@gmail.com', 4, N'softpro')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'e8fb14bc-cff9-4d9b-a6f7-d5b1defafcaf', 0, N'd654d1a1-672c-4921-8919-67a38c1d5de8', N'gm@g.com', 1, 1, NULL, N'GM@G.COM', N'GOOGLE', N'AQAAAAEAACcQAAAAEH069rfHhZ7t0umHLoSLfXDOUE34fASDeTTRlSNY8ToM9e1gcHc4HWlxFcbc7GWfdQ==', NULL, 0, N'6bc531a2-6140-4179-94b4-48803f34a3a4', 0, N'google', 2, N'Coder Inn')
INSERT [dbo].[AspNetUsers] ([Id], [AccessFailedCount], [ConcurrencyStamp], [Email], [EmailConfirmed], [LockoutEnabled], [LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UserName], [CompanyId], [CompanyName]) VALUES (N'ec1624d9-b40c-4e82-af03-0c49acfa6ac5', 0, N'3b1180e5-f809-4839-8a04-da781f48e2e4', N's@c.com', 1, 1, NULL, N'S@C.COM', N'SM', N'AQAAAAEAACcQAAAAEIiQ3jRITGS/c7kYBKgbYk3uzrjlbK/P7LoOUYObgYj6j0VxC87xEi1maJw9/qq96A==', NULL, 0, N'29e9a722-7204-48e1-8083-a99da61dc444', 0, N'sm', 2, N'Coder Inn')
SET IDENTITY_INSERT [dbo].[Authorization_AllowedCities] ON 

INSERT [dbo].[Authorization_AllowedCities] ([AllowedCitiesId], [UserId], [CityId]) VALUES (1, N'2ef76e02-0413-4111-b494-3f67b30332be', 20)
INSERT [dbo].[Authorization_AllowedCities] ([AllowedCitiesId], [UserId], [CityId]) VALUES (2, N'2ef76e02-0413-4111-b494-3f67b30332be', 21)
SET IDENTITY_INSERT [dbo].[Authorization_AllowedCities] OFF
SET IDENTITY_INSERT [dbo].[Authorization_AllowedCountries] ON 

INSERT [dbo].[Authorization_AllowedCountries] ([AllowedCountriesId], [UserId], [CountryId]) VALUES (9, N'2ef76e02-0413-4111-b494-3f67b30332be', 45)
INSERT [dbo].[Authorization_AllowedCountries] ([AllowedCountriesId], [UserId], [CountryId]) VALUES (10, N'2ef76e02-0413-4111-b494-3f67b30332be', 46)
SET IDENTITY_INSERT [dbo].[Authorization_AllowedCountries] OFF
SET IDENTITY_INSERT [dbo].[Authorization_AllowedDatacenters] ON 

INSERT [dbo].[Authorization_AllowedDatacenters] ([AllowedDatacentersId], [UserId], [DatacenterId]) VALUES (1, N'2ef76e02-0413-4111-b494-3f67b30332be', 29)
INSERT [dbo].[Authorization_AllowedDatacenters] ([AllowedDatacentersId], [UserId], [DatacenterId]) VALUES (2, N'2ef76e02-0413-4111-b494-3f67b30332be', 30)
SET IDENTITY_INSERT [dbo].[Authorization_AllowedDatacenters] OFF
SET IDENTITY_INSERT [dbo].[Authorization_AllowedDepartments] ON 

INSERT [dbo].[Authorization_AllowedDepartments] ([AllowedDepartmentsId], [UserId], [DepartmentId]) VALUES (1, N'2ef76e02-0413-4111-b494-3f67b30332be', 49)
INSERT [dbo].[Authorization_AllowedDepartments] ([AllowedDepartmentsId], [UserId], [DepartmentId]) VALUES (2, N'2ef76e02-0413-4111-b494-3f67b30332be', 50)
SET IDENTITY_INSERT [dbo].[Authorization_AllowedDepartments] OFF
SET IDENTITY_INSERT [dbo].[Authorization_AllowedStates] ON 

INSERT [dbo].[Authorization_AllowedStates] ([AllowedStatesId], [UserId], [StateId]) VALUES (3, N'2ef76e02-0413-4111-b494-3f67b30332be', 38)
INSERT [dbo].[Authorization_AllowedStates] ([AllowedStatesId], [UserId], [StateId]) VALUES (4, N'2ef76e02-0413-4111-b494-3f67b30332be', 37)
SET IDENTITY_INSERT [dbo].[Authorization_AllowedStates] OFF
SET IDENTITY_INSERT [dbo].[Contact] ON 

INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (16, N'firstname', N'lastname', N'm', N'email@email.com', N'phone', N'title', N'login', N'sid', NULL, 1, 3, 6071)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (17, N'usmanidrees', N'last', N'm', N'email@email.com', N'Phone', N'title', N'Login', N'SID', NULL, 0, 2, 6073)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (18, N'usmanidrees', N'last', N'm', N'email@email.com', N'phone', N'title', N'loginanme', N'SID', NULL, 0, 2, 6074)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (19, N'Masoom', N'fairshta', N'm', N'email@email.com', N'Phone', N'Title', N'LoginName', N'SID', NULL, 0, 2, 6077)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (20, N'abc', N'xyz', N'm', N'emil@email.com', N'phone', N'title', N'login', N'SID', NULL, 0, 2, 6078)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (21, N'usmanidrees', N'last', N'm', N'email@email.com', N'phone', N'title', N'login', N'SID', NULL, 0, 2, 6079)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (22, N'usmanidrees', N'last', N'm', N'email@email.com', N'phone', N'title', N'login', N'sid', NULL, 0, 2, 6080)
INSERT [dbo].[Contact] ([ContactID], [FirstName], [LastName], [MiddleInitial], [Email], [Phone], [Title], [LoginName], [SID], [EmployeeNo], [IsValid], [ContactTypeID], [ApplicationID]) VALUES (23, N'usmanidrees', N'last', N'm', N'email', N'phone', N'title', N'login', N'sid', NULL, 0, 2, 6081)
SET IDENTITY_INSERT [dbo].[Contact] OFF
SET IDENTITY_INSERT [dbo].[DatabaseDocument] ON 

INSERT [dbo].[DatabaseDocument] ([DatabaseDocumentID], [DatabaseID], [DocumentID]) VALUES (1003, 3011, 5)
INSERT [dbo].[DatabaseDocument] ([DatabaseDocumentID], [DatabaseID], [DocumentID]) VALUES (1004, 3012, 5)
INSERT [dbo].[DatabaseDocument] ([DatabaseDocumentID], [DatabaseID], [DocumentID]) VALUES (1005, 3013, 5)
INSERT [dbo].[DatabaseDocument] ([DatabaseDocumentID], [DatabaseID], [DocumentID]) VALUES (1006, 3014, 5)
INSERT [dbo].[DatabaseDocument] ([DatabaseDocumentID], [DatabaseID], [DocumentID]) VALUES (1007, 3015, 5)
SET IDENTITY_INSERT [dbo].[DatabaseDocument] OFF
SET IDENTITY_INSERT [dbo].[Databases] ON 

INSERT [dbo].[Databases] ([DatabaseID], [Name], [DBTypeID], [DBVersion], [InstallerNameID], [InstalledDate], [ServicePack], [DbaID], [IsDevDB], [IsTestDB], [IsProdDB], [Comments], [LastUpdatedBy], [LastUpdated], [DBTechnology]) VALUES (3011, N'jhjhkb', 6, N'', 5, CAST(0x0000ABAB00000000 AS DateTime), N'', 1, 0, 0, 0, N'', NULL, CAST(0x0000ABAB00FD9EC9 AS DateTime), NULL)
INSERT [dbo].[Databases] ([DatabaseID], [Name], [DBTypeID], [DBVersion], [InstallerNameID], [InstalledDate], [ServicePack], [DbaID], [IsDevDB], [IsTestDB], [IsProdDB], [Comments], [LastUpdatedBy], [LastUpdated], [DBTechnology]) VALUES (3012, N'test', 9, N'86', 6, CAST(0x0000ABAB00000000 AS DateTime), N'', 1, 0, 0, 0, N'', NULL, CAST(0x0000ABAB0105BF6E AS DateTime), NULL)
INSERT [dbo].[Databases] ([DatabaseID], [Name], [DBTypeID], [DBVersion], [InstallerNameID], [InstalledDate], [ServicePack], [DbaID], [IsDevDB], [IsTestDB], [IsProdDB], [Comments], [LastUpdatedBy], [LastUpdated], [DBTechnology]) VALUES (3013, N'abcde', 2, N'version', 3, CAST(0x0000ABF100000000 AS DateTime), N'pack', 1, 0, 0, 0, N'comment', NULL, CAST(0x0000ABF100E7766F AS DateTime), N'tech')
INSERT [dbo].[Databases] ([DatabaseID], [Name], [DBTypeID], [DBVersion], [InstallerNameID], [InstalledDate], [ServicePack], [DbaID], [IsDevDB], [IsTestDB], [IsProdDB], [Comments], [LastUpdatedBy], [LastUpdated], [DBTechnology]) VALUES (3014, N'masoom', 2, N'ver', 3, CAST(0x0000ABF100000000 AS DateTime), N'pack', 1, 0, 0, 0, N'comment', NULL, CAST(0x0000ABF100E88B30 AS DateTime), N'tech')
INSERT [dbo].[Databases] ([DatabaseID], [Name], [DBTypeID], [DBVersion], [InstallerNameID], [InstalledDate], [ServicePack], [DbaID], [IsDevDB], [IsTestDB], [IsProdDB], [Comments], [LastUpdatedBy], [LastUpdated], [DBTechnology]) VALUES (3015, N'abcdefghi', 2, N'ver', 3, CAST(0x0000ABF100000000 AS DateTime), N'pack', 1, 0, 0, 0, N'comment', NULL, CAST(0x0000ABF100E8DFB5 AS DateTime), N'tech')
SET IDENTITY_INSERT [dbo].[Databases] OFF
SET IDENTITY_INSERT [dbo].[Document] ON 

INSERT [dbo].[Document] ([DocumentID], [Name], [Path]) VALUES (5, N'test', N'check')
SET IDENTITY_INSERT [dbo].[Document] OFF
SET IDENTITY_INSERT [dbo].[framework_applicationlocation] ON 

INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1, 3018, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (2, 4002, 20, 44, 38, 52, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (3, 6012, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (4, 6015, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (5, 6016, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (6, 6019, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (7, 6033, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (8, 6034, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (9, 6035, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (10, 6036, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (11, 6038, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (12, 6040, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (13, 6041, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (14, 6055, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (15, 6056, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (16, 6059, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (17, 6060, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (18, 6061, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (19, 6062, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (20, 6063, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (999, 6069, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1000, 6070, 20, 44, 38, 50, 29)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1001, 6071, 22, 45, 40, 55, 32)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1002, 6072, 22, 45, 40, 55, 32)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1003, 6073, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1004, 6074, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1005, 6077, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1006, 6078, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1007, 6079, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1008, 6080, 1, 52, 43, 1, 1)
INSERT [dbo].[framework_applicationlocation] ([Framework_applicationlocationID], [ApplicationID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1009, 6081, 1, 52, 43, 1, 1)
SET IDENTITY_INSERT [dbo].[framework_applicationlocation] OFF
SET IDENTITY_INSERT [dbo].[Framework_Databases_Location] ON 

INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (1, 3004, 20, 44, 38, 50, 29)
INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (2, 3011, 22, 45, 40, 55, 32)
INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (3, 3012, 22, 45, 40, 55, 32)
INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (4, 3013, 1, 52, 43, 1, 1)
INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (5, 3014, 1, 52, 43, 1, 1)
INSERT [dbo].[Framework_Databases_Location] ([Framework_Database_LocationID], [DatabaseID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (6, 3015, 1, 52, 43, 1, 1)
SET IDENTITY_INSERT [dbo].[Framework_Databases_Location] OFF
SET IDENTITY_INSERT [dbo].[Framework_Server_Location] ON 

INSERT [dbo].[Framework_Server_Location] ([Framework_Server_LocationID], [ServerID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (7, 5023, 22, 45, 40, 55, 32)
INSERT [dbo].[Framework_Server_Location] ([Framework_Server_LocationID], [ServerID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (8, 5024, 1, 52, 43, 1, 1)
INSERT [dbo].[Framework_Server_Location] ([Framework_Server_LocationID], [ServerID], [CityId], [CountryId], [StateId], [DepartmentId], [DataCenterId]) VALUES (9, 5025, 1, 52, 43, 1, 1)
SET IDENTITY_INSERT [dbo].[Framework_Server_Location] OFF
SET IDENTITY_INSERT [dbo].[GGPDeveloper] ON 

INSERT [dbo].[GGPDeveloper] ([GGPDeveloperID], [LeadDeveloper], [BusinessAnalyst], [ProgrammingLanguageID]) VALUES (1, N'1', N'1', 1)
SET IDENTITY_INSERT [dbo].[GGPDeveloper] OFF
SET IDENTITY_INSERT [dbo].[lkpAllCities] ON 

INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1, N'New York', N' New York', N'40.6635', N'-73.9387', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (2, N'Los Angeles', N' California', N'34.0194', N'-118.4108', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (3, N'Chicago', N' Illinois', N'41.8376', N'-87.6818', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (4, N'Houston', N' Texas', N'29.7866', N'-95.3909', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (5, N'Phoenix', N' Arizona', N'33.5722', N'-112.0901', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (6, N'Philadelphia', N' Pennsylvania', N'40.0094', N'-75.1333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (7, N'San Antonio', N' Texas', N'29.4724', N'-98.5251', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (8, N'San Diego', N' California', N'32.8153', N'-117.135', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (9, N'Dallas', N' Texas', N'32.7933', N'-96.7665', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (10, N'San Jose', N' California', N'37.2967', N'-121.8189', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (11, N'Austin', N' Texas', N'30.3039', N'-97.7544', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (12, N'Jacksonville', N' Florida', N'30.3369', N'-81.6616', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (13, N'San Francisco', N' California', N'37.7272', N'-123.0322', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (14, N'Columbus', N' Ohio', N'39.9852', N'-82.9848', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (15, N'Fort Worth', N' Texas', N'32.7815', N'-97.3467', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (16, N'Indianapolis', N' Indiana', N'39.7767', N'-86.1459', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (17, N'Charlotte', N' North Carolina', N'35.2078', N'-80.831', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (18, N'Seattle', N' Washington', N'47.6205', N'-122.3509', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (19, N'Denver', N' Colorado', N'39.7619', N'-104.8811', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (20, N'Washington', N' District of Columbia', N'38.9041', N'-77.0172', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (21, N'Boston', N' Massachusetts', N'42.332', N'-71.0202', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (22, N'El Paso', N' Texas', N'31.8484', N'-106.427', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (23, N'Detroit', N' Michigan', N'42.383', N'-83.1022', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (24, N'Nashville', N' Tennessee', N'36.1718', N'-86.785', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (25, N'Memphis', N' Tennessee', N'35.1028', N'-89.9774', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (26, N'Portland', N' Oregon', N'45.537', N'-122.65', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (27, N'Oklahoma City', N' Oklahoma', N'35.4671', N'-97.5137', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (28, N'Las Vegas', N' Nevada', N'36.2292', N'-115.2601', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (29, N'Louisville', N' Kentucky', N'38.1654', N'-85.6474', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (30, N'Baltimore', N' Maryland', N'39.3', N'-76.6105', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (31, N'Milwaukee', N' Wisconsin', N'43.0633', N'-87.9667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (32, N'Albuquerque', N' New Mexico', N'35.1056', N'-106.6474', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (33, N'Tucson', N' Arizona', N'32.1531', N'-110.8706', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (34, N'Fresno', N' California', N'36.7836', N'-119.7934', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (35, N'Sacramento', N' California', N'38.5666', N'-121.4686', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (36, N'Mesa', N' Arizona', N'33.4019', N'-111.7174', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (37, N'Kansas City', N' Missouri', N'39.1251', N'-94.551', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (38, N'Atlanta', N' Georgia', N'33.7629', N'-84.4227', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (39, N'Long Beach', N' California', N'33.8092', N'-118.1553', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (40, N'Omaha', N' Nebraska', N'41.2644', N'-96.0451', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (41, N'Raleigh', N' North Carolina', N'35.8306', N'-78.6418', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (42, N'Colorado Springs', N' Colorado', N'38.8673', N'-104.7607', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (43, N'Miami', N' Florida', N'25.7752', N'-80.2086', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (44, N'Virginia Beach', N' Virginia', N'36.78', N'-76.0252', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (45, N'Oakland', N' California', N'37.7698', N'-122.2257', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (46, N'Minneapolis', N' Minnesota', N'44.9633', N'-93.2683', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (47, N'Tulsa', N' Oklahoma', N'36.1279', N'-95.9023', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (48, N'Arlington', N' Texas', N'32.7007', N'-97.1247', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (49, N'New Orleans', N' Louisiana', N'30.0534', N'-89.9345', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (50, N'Wichita', N' Kansas', N'37.6907', N'-97.3459', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (51, N'Cleveland', N' Ohio', N'41.4785', N'-81.6794', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (52, N'Tampa', N' Florida', N'27.9701', N'-82.4797', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (53, N'Bakersfield', N' California', N'35.3212', N'-119.0183', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (54, N'Aurora', N' Colorado', N'39.688', N'-104.6897', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (55, N'Anaheim', N' California', N'33.8555', N'-117.7601', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (56, N'Honolulu', N' Hawaii', N'21.3243', N'-157.8476', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (57, N'Santa Ana', N' California', N'33.7363', N'-117.883', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (58, N'Riverside', N' California', N'33.9381', N'-117.3932', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (59, N'Corpus Christi', N' Texas', N'27.7543', N'-97.1734', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (60, N'Lexington', N' Kentucky', N'38.0407', N'-84.4583', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (61, N'Stockton', N' California', N'37.9763', N'-121.3133', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (62, N'St. Louis', N' Missouri', N'38.6357', N'-90.2446', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (63, N'Saint Paul', N' Minnesota', N'44.9489', N'-93.1041', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (64, N'Henderson', N' Nevada', N'36.0097', N'-115.0357', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (65, N'Pittsburgh', N' Pennsylvania', N'40.4398', N'-79.9766', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (66, N'Cincinnati', N' Ohio', N'39.1402', N'-84.5058', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (67, N'Anchorage', N' Alaska', N'61.1743', N'-149.2843', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (68, N'Greensboro', N' North Carolina', N'36.0951', N'-79.827', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (69, N'Plano', N' Texas', N'33.0508', N'-96.7479', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (70, N'Newark', N' New Jersey', N'40.7242', N'-74.1726', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (71, N'Lincoln', N' Nebraska', N'40.8105', N'-96.6803', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (72, N'Orlando', N' Florida', N'28.4166', N'-81.2736', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (73, N'Irvine', N' California', N'33.6784', N'-117.7713', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (74, N'Toledo', N' Ohio', N'41.6641', N'-83.5819', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (75, N'Jersey City', N' New Jersey', N'40.7114', N'-74.0648', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (76, N'Chula Vista', N' California', N'32.6277', N'-117.0152', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (77, N'Durham', N' North Carolina', N'35.9811', N'-78.9029', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (78, N'Fort Wayne', N' Indiana', N'41.0882', N'-85.1439', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (79, N'St. Petersburg', N' Florida', N'27.762', N'-82.6441', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (80, N'Laredo', N' Texas', N'27.5604', N'-99.4892', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (81, N'Buffalo', N' New York', N'42.8925', N'-78.8597', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (82, N'Madison', N' Wisconsin', N'43.0878', N'-89.4299', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (83, N'Lubbock', N' Texas', N'33.5656', N'-101.8867', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (84, N'Chandler', N' Arizona', N'33.2829', N'-111.8549', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (85, N'Scottsdale', N' Arizona', N'33.6843', N'-111.8611', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (86, N'Reno', N' Nevada', N'39.5491', N'-119.8499', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (87, N'Glendale', N' Arizona', N'33.5331', N'-112.1899', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (88, N'Norfolk', N' Virginia', N'36.923', N'-76.2446', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (89, N'Winston–Salem', N' North Carolina', N'36.1027', N'-80.261', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (90, N'North Las Vegas', N' Nevada', N'36.2857', N'-115.0939', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (91, N'Gilbert', N' Arizona', N'33.3103', N'-111.7431', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (92, N'Chesapeake', N' Virginia', N'36.6794', N'-76.3018', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (93, N'Irving', N' Texas', N'32.8577', N'-96.97', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (94, N'Hialeah', N' Florida', N'25.8699', N'-80.3029', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (95, N'Garland', N' Texas', N'32.9098', N'-96.6303', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (96, N'Fremont', N' California', N'37.4945', N'-121.9412', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (97, N'Richmond', N' Virginia', N'37.5314', N'-77.476', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (98, N'Boise', N' Idaho', N'43.6002', N'-116.2317', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (99, N'Baton Rouge', N' Louisiana', N'30.4422', N'-91.1309', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (100, N'Des Moines', N' Iowa', N'41.5726', N'-93.6102', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (101, N'Spokane', N' Washington', N'47.6669', N'-117.4333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (102, N'San Bernardino', N' California', N'34.1416', N'-117.2936', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (103, N'Modesto', N' California', N'37.6375', N'-121.003', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (104, N'Tacoma', N' Washington', N'47.2522', N'-122.4598', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (105, N'Fontana', N' California', N'34.109', N'-117.4629', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (106, N'Santa Clarita', N' California', N'34.403', N'-118.5042', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (107, N'Birmingham', N' Alabama', N'33.5274', N'-86.799', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (108, N'Oxnard', N' California', N'34.2023', N'-119.2046', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (109, N'Fayetteville', N' North Carolina', N'35.0828', N'-78.9735', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (110, N'Rochester', N' New York', N'43.1699', N'-77.6169', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (111, N'Moreno Valley', N' California', N'33.9233', N'-117.2057', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (112, N'Glendale', N' California', N'34.1814', N'-118.2458', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (113, N'Yonkers', N' New York', N'40.9459', N'-73.8674', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (114, N'Huntington Beach', N' California', N'33.6906', N'-118.0093', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (115, N'Aurora', N' Illinois', N'41.7635', N'-88.2901', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (116, N'Salt Lake City', N' Utah', N'40.7769', N'-111.931', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (117, N'Amarillo', N' Texas', N'35.1999', N'-101.8302', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (118, N'Montgomery', N' Alabama', N'32.3472', N'-86.2661', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (119, N'Grand Rapids', N' Michigan', N'42.9612', N'-85.6556', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (120, N'Little Rock', N' Arkansas', N'34.7254', N'-92.3586', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (121, N'Akron', N' Ohio', N'41.0805', N'-81.5214', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (122, N'Augusta', N' Georgia', N'33.3655', N'-82.0734', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (123, N'Huntsville', N' Alabama', N'34.699', N'-86.673', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (124, N'Columbus', N' Georgia', N'32.5102', N'-84.8749', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (125, N'Grand Prairie', N' Texas', N'32.6869', N'-97.0211', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (126, N'Shreveport', N' Louisiana', N'32.4669', N'-93.7922', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (127, N'Overland Park', N' Kansas', N'38.889', N'-94.6906', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (128, N'Tallahassee', N' Florida', N'30.4551', N'-84.2534', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (129, N'Mobile', N' Alabama', N'30.6684', N'-88.1002', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (130, N'Port St. Lucie', N' Florida', N'27.2806', N'-80.3883', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (131, N'Knoxville', N' Tennessee', N'35.9707', N'-83.9493', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (132, N'Worcester', N' Massachusetts', N'42.2695', N'-71.8078', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (133, N'Tempe', N' Arizona', N'33.3884', N'-111.9318', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (134, N'Cape Coral', N' Florida', N'26.6432', N'-81.9974', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (135, N'Brownsville', N' Texas', N'25.9991', N'-97.455', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (136, N'McKinney', N' Texas', N'33.1985', N'-96.668', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (137, N'Providence', N' Rhode Island', N'41.8231', N'-71.4188', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (138, N'Fort Lauderdale', N' Florida', N'26.1412', N'-80.1467', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (139, N'Newport News', N' Virginia', N'37.0762', N'-76.522', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (140, N'Chattanooga', N' Tennessee', N'35.066', N'-85.2484', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (141, N'Rancho Cucamonga', N' California', N'34.1233', N'-117.5642', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (142, N'Frisco', N' Texas', N'33.1554', N'-96.8226', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (143, N'Sioux Falls', N' South Dakota', N'43.5383', N'-96.732', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (144, N'Oceanside', N' California', N'33.2245', N'-117.3062', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (145, N'Ontario', N' California', N'34.0394', N'-117.6042', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (146, N'Vancouver', N' Washington', N'45.6349', N'-122.5957', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (147, N'Santa Rosa', N' California', N'38.4468', N'-122.7061', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (148, N'Garden Grove', N' California', N'33.7788', N'-117.9605', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (149, N'Elk Grove', N' California', N'38.4146', N'-121.385', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (150, N'Pembroke Pines', N' Florida', N'26.021', N'-80.3404', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (151, N'Salem', N' Oregon', N'44.9237', N'-123.0232', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (152, N'Eugene', N' Oregon', N'44.0567', N'-123.1162', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (153, N'Peoria', N' Arizona', N'33.7862', N'-112.308', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (154, N'Corona', N' California', N'33.862', N'-117.5655', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (155, N'Springfield', N' Missouri', N'37.1942', N'-93.2913', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (156, N'Jackson', N' Mississippi', N'32.3158', N'-90.2128', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (157, N'Cary', N' North Carolina', N'35.7809', N'-78.8133', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (158, N'Fort Collins', N' Colorado', N'40.5482', N'-105.0648', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (159, N'Hayward', N' California', N'37.6287', N'-122.1024', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (160, N'Lancaster', N' California', N'34.6936', N'-118.1753', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (161, N'Alexandria', N' Virginia', N'38.8201', N'-77.0841', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (162, N'Salinas', N' California', N'36.6902', N'-121.6337', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (163, N'Palmdale', N' California', N'34.591', N'-118.1054', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (164, N'Lakewood', N' Colorado', N'39.6989', N'-105.1176', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (165, N'Springfield', N' Massachusetts', N'42.1155', N'-72.54', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (166, N'Sunnyvale', N' California', N'37.3858', N'-122.0263', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (167, N'Hollywood', N' Florida', N'26.031', N'-80.1646', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (168, N'Pasadena', N' Texas', N'29.6586', N'-95.1506', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (169, N'Clarksville', N' Tennessee', N'36.5664', N'-87.3452', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (170, N'Pomona', N' California', N'34.0585', N'-117.7611', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (171, N'Kansas City', N' Kansas', N'39.1225', N'-94.7418', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (172, N'Macon', N' Georgia', N'32.8088', N'-83.6942', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (173, N'Escondido', N' California', N'33.1331', N'-117.074', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (174, N'Paterson', N' New Jersey', N'40.9148', N'-74.1628', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (175, N'Joliet', N' Illinois', N'41.5177', N'-88.1488', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (176, N'Naperville', N' Illinois', N'41.7492', N'-88.162', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (177, N'Rockford', N' Illinois', N'42.2588', N'-89.0646', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (178, N'Torrance', N' California', N'33.835', N'-118.3414', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (179, N'Bridgeport', N' Connecticut', N'41.1874', N'-73.1958', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (180, N'Savannah', N' Georgia', N'32.0025', N'-81.1536', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (181, N'Killeen', N' Texas', N'31.0777', N'-97.732', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (182, N'Bellevue', N' Washington', N'47.5979', N'-122.1565', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (183, N'Mesquite', N' Texas', N'32.7629', N'-96.5888', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (184, N'Syracuse', N' New York', N'43.041', N'-76.1436', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (185, N'McAllen', N' Texas', N'26.2322', N'-98.2464', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (186, N'Pasadena', N' California', N'34.1606', N'-118.1396', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (187, N'Orange', N' California', N'33.787', N'-117.8613', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (188, N'Fullerton', N' California', N'33.8857', N'-117.928', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (189, N'Dayton', N' Ohio', N'39.7774', N'-84.1996', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (190, N'Miramar', N' Florida', N'25.977', N'-80.3358', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (191, N'Olathe', N' Kansas', N'38.8843', N'-94.8195', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (192, N'Thornton', N' Colorado', N'39.9194', N'-104.9428', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (193, N'Waco', N' Texas', N'31.5601', N'-97.186', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (194, N'Murfreesboro', N' Tennessee', N'35.8522', N'-86.416', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (195, N'Denton', N' Texas', N'33.2166', N'-97.1414', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (196, N'West Valley City', N' Utah', N'40.6885', N'-112.0118', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (197, N'Midland', N' Texas', N'32.0246', N'-102.1135', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (198, N'Carrollton', N' Texas', N'32.9884', N'-96.8998', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (199, N'Roseville', N' California', N'38.769', N'-121.3189', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (200, N'Warren', N' Michigan', N'42.4929', N'-83.025', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (201, N'Charleston', N' South Carolina', N'32.8179', N'-79.959', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (202, N'Hampton', N' Virginia', N'37.048', N'-76.2971', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (203, N'Surprise', N' Arizona', N'33.6706', N'-112.4527', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (204, N'Columbia', N' South Carolina', N'34.0291', N'-80.898', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (205, N'Coral Springs', N' Florida', N'26.2707', N'-80.2593', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (206, N'Visalia', N' California', N'36.3273', N'-119.3289', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (207, N'Sterling Heights', N' Michigan', N'42.5812', N'-83.0303', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (208, N'Gainesville', N' Florida', N'29.6788', N'-82.3461', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (209, N'Cedar Rapids', N' Iowa', N'41.967', N'-91.6778', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (210, N'New Haven', N' Connecticut', N'41.3108', N'-72.925', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (211, N'Stamford', N' Connecticut', N'41.0799', N'-73.546', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (212, N'Elizabeth', N' New Jersey', N'40.6664', N'-74.1935', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (213, N'Concord', N' California', N'37.9722', N'-122.0016', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (214, N'Thousand Oaks', N' California', N'34.1933', N'-118.8742', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (215, N'Kent', N' Washington', N'47.388', N'-122.2127', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (216, N'Santa Clara', N' California', N'37.3646', N'-121.9679', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (217, N'Simi Valley', N' California', N'34.2669', N'-118.7485', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (218, N'Lafayette', N' Louisiana', N'30.2074', N'-92.0285', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (219, N'Topeka', N' Kansas', N'39.0347', N'-95.6962', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (220, N'Athens', N' Georgia', N'33.9496', N'-83.3701', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (221, N'Round Rock', N' Texas', N'30.5252', N'-97.666', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (222, N'Hartford', N' Connecticut', N'41.7659', N'-72.6816', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (223, N'Norman', N' Oklahoma', N'35.2406', N'-97.3453', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (224, N'Victorville', N' California', N'34.5277', N'-117.3536', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (225, N'Fargo', N'  North Dakota', N'46.8652', N'-96.829', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (226, N'Berkeley', N' California', N'37.867', N'-122.2991', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (227, N'Vallejo', N' California', N'38.1079', N'-122.264', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (228, N'Abilene', N' Texas', N'32.4545', N'-99.7381', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (229, N'Columbia', N' Missouri', N'38.951561', N'-92.328638', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (230, N'Ann Arbor', N' Michigan', N'42.2761', N'-83.7309', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (231, N'Allentown', N' Pennsylvania', N'40.5936', N'-75.4784', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (232, N'Pearland', N' Texas', N'29.5558', N'-95.3231', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (233, N'Beaumont', N' Texas', N'30.0849', N'-94.1453', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (234, N'Wilmington', N' North Carolina', N'34.2092', N'-77.8858', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (235, N'Evansville', N' Indiana', N'37.9877', N'-87.5347', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (236, N'Arvada', N' Colorado', N'39.8337', N'-105.1503', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (237, N'Provo', N' Utah', N'40.2453', N'-111.6448', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (238, N'Independence', N' Missouri', N'39.0855', N'-94.3521', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (239, N'Lansing', N' Michigan', N'42.7143', N'-84.5593', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (240, N'Odessa', N' Texas', N'31.8838', N'-102.3411', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (241, N'Richardson', N' Texas', N'32.9723', N'-96.7081', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (242, N'Fairfield', N' California', N'38.2593', N'-122.0321', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (243, N'El Monte', N' California', N'34.0746', N'-118.0291', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (244, N'Rochester', N' Minnesota', N'44.0154', N'-92.4772', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (245, N'Clearwater', N' Florida', N'27.9789', N'-82.7666', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (246, N'Carlsbad', N' California', N'33.1239', N'-117.2828', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (247, N'Springfield', N' Illinois', N'39.7911', N'-89.6446', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (248, N'Temecula', N' California', N'33.4931', N'-117.1317', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (249, N'West Jordan', N' Utah', N'40.6024', N'-112.0008', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (250, N'Costa Mesa', N' California', N'33.6659', N'-117.9123', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (251, N'Miami Gardens', N' Florida', N'25.9489', N'-80.2436', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (252, N'Cambridge', N' Massachusetts', N'42.376', N'-71.1187', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (253, N'College Station', N' Texas', N'30.5852', N'-96.2964', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (254, N'Murrieta', N' California', N'33.5721', N'-117.1904', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (255, N'Downey', N' California', N'33.9382', N'-118.1309', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (256, N'Peoria', N' Illinois', N'40.7515', N'-89.6174', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (257, N'Westminster', N' Colorado', N'39.8822', N'-105.0644', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (258, N'Elgin', N' Illinois', N'42.0396', N'-88.3217', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (259, N'Antioch', N' California', N'37.9791', N'-121.7962', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (260, N'Palm Bay', N' Florida', N'27.9856', N'-80.6626', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (261, N'High Point', N' North Carolina', N'35.99', N'-79.9905', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (262, N'Lowell', N' Massachusetts', N'42.639', N'-71.3211', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (263, N'Manchester', N' New Hampshire', N'42.9849', N'-71.4441', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (264, N'Pueblo', N' Colorado', N'38.2699', N'-104.6123', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (265, N'Gresham', N' Oregon', N'45.5023', N'-122.4416', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (266, N'North Charleston', N' South Carolina', N'32.9178', N'-80.065', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (267, N'Ventura', N' California', N'34.2678', N'-119.2542', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (268, N'Inglewood', N' California', N'33.9561', N'-118.3443', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (269, N'Pompano Beach', N' Florida', N'26.2416', N'-80.1339', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (270, N'Centennial', N' Colorado', N'39.5906', N'-104.8691', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (271, N'West Palm Beach', N' Florida', N'26.7464', N'-80.1251', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (272, N'Everett', N' Washington', N'47.9566', N'-122.1914', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (273, N'Richmond', N' California', N'37.9523', N'-122.3606', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (274, N'Clovis', N' California', N'36.8282', N'-119.6849', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (275, N'Billings', N' Montana', N'45.7885', N'-108.5499', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (276, N'Waterbury', N' Connecticut', N'41.5585', N'-73.0367', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (277, N'Broken Arrow', N' Oklahoma', N'36.0365', N'-95.781', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (278, N'Lakeland', N' Florida', N'28.0555', N'-81.9549', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (279, N'West Covina', N' California', N'34.0559', N'-117.9099', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (280, N'Boulder', N' Colorado', N'40.027', N'-105.2519', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (281, N'Daly City', N' California', N'37.7009', N'-122.465', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (282, N'Santa Maria', N' California', N'34.9332', N'-120.4438', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (283, N'Hillsboro', N' Oregon', N'45.528', N'-122.9357', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (284, N'Sandy Springs', N' Georgia', N'33.9315', N'-84.3687', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (285, N'Norwalk', N' California', N'33.9076', N'-118.0835', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (286, N'Jurupa Valley', N' California', N'34.0026', N'-117.4676', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (287, N'Lewisville', N' Texas', N'33.0466', N'-96.9818', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (288, N'Greeley', N' Colorado', N'40.4153', N'-104.7697', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (289, N'Davie', N' Florida', N'26.0791', N'-80.285', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (290, N'Green Bay', N' Wisconsin', N'44.5207', N'-87.9842', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (291, N'Tyler', N' Texas', N'32.3173', N'-95.3059', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (292, N'League City', N' Texas', N'29.4901', N'-95.1091', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (293, N'Burbank', N' California', N'34.1901', N'-118.3264', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (294, N'San Mateo', N' California', N'37.5603', N'-122.3106', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (295, N'Wichita Falls', N' Texas', N'33.9067', N'-98.5259', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (296, N'El Cajon', N' California', N'32.8017', N'-116.9604', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (297, N'Rialto', N' California', N'34.1118', N'-117.3883', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (298, N'Lakewood', N' New Jersey', N'40.0771', N'-74.2004', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (299, N'Edison', N' New Jersey', N'40.504', N'-74.3494', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (300, N'Davenport', N' Iowa', N'41.5541', N'-90.604', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (301, N'South Bend', N' Indiana', N'41.6769', N'-86.269', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (302, N'Woodbridge', N' New Jersey', N'40.5607', N'-74.2927', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (303, N'Las Cruces', N' New Mexico', N'32.3264', N'-106.7897', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (304, N'Vista', N' California', N'33.1895', N'-117.2386', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (305, N'Renton', N' Washington', N'47.4761', N'-122.192', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (306, N'Sparks', N' Nevada', N'39.5544', N'-119.7356', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (307, N'Clinton', N' Michigan', N'42.5903', N'-82.917', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (308, N'Allen', N' Texas', N'33.0997', N'-96.6631', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (309, N'Tuscaloosa', N' Alabama', N'33.2065', N'-87.5346', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (310, N'San Angelo', N' Texas', N'31.4411', N'-100.4505', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (311, N'Vacaville', N' California', N'38.3539', N'-121.9728', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (312, N'Karachi', N'Sindh', N'24.9056', N'67.0822', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (313, N'Lahore', N'15', N'31.549722', N'74.343611', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (314, N'Faisalabad', N'Punjab', N'31.416667', N'73.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (315, N'Serai', N'Khyber Pakhtunkhwa', N'34.73933', N'72.335655', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (316, N'Rawalpindi', N'Punjab', N'33.597331', N'73.047904', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (317, N'Multan', N'Punjab', N'30.196789', N'71.478241', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (318, N'Gujranwala', N'Punjab', N'32.155667', N'74.187052', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (319, N'Hyderabad City', N'Sindh', N'25.396891', N'68.377183', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (320, N'Peshawar', N'Khyber Pakhtunkhwa', N'34.008', N'71.578488', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (321, N'Abbottabad', N'Khyber Pakhtunkhwa', N'34.1463', N'73.211684', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (322, N'Islamabad', N'Islamabad', N'33.69', N'73.0551', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (323, N'Quetta', N'Balochistan', N'30.184138', N'67.00141', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (324, N'Bannu', N'Khyber Pakhtunkhwa', N'32.985414', N'70.602701', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (325, N'Bahawalpur', N'Punjab', N'29.4', N'71.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (326, N'Sargodha', N'Punjab', N'32.083611', N'72.671111', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (327, N'Sialkot City', N'Punjab', N'32.499101', N'74.52502', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (328, N'Sukkur', N'Sindh', N'27.705164', N'68.857383', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (329, N'Larkana', N'Sindh', N'27.558985', N'68.212035', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (330, N'Sheikhupura', N'Punjab', N'31.713056', N'73.978333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (331, N'Mirpur Khas', N'Sindh', N'25.5251', N'69.0159', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (332, N'Rahimyar Khan', N'Punjab', N'28.419482', N'70.302386', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (333, N'Kohat', N'Khyber Pakhtunkhwa', N'33.581958', N'71.449291', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (334, N'Jhang Sadr', N'Punjab', N'31.269811', N'72.316867', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (335, N'Gujrat', N'Punjab', N'32.574204', N'74.075423', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (336, N'Bardar', N'Khyber Pakhtunkhwa', N'34.163737', N'72.011571', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (337, N'Kasur', N'Punjab', N'31.115556', N'74.446667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (338, N'Dera Ghazi Khan', N'Punjab', N'30.056142', N'70.634766', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (339, N'Masiwala', N'Punjab', N'30.683333', N'73.066667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (340, N'Nawabshah', N'Sindh', N'26.248334', N'68.409554', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (341, N'Okara', N'Punjab', N'30.808056', N'73.445833', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (342, N'Gilgit', N'Gilgit-Baltistan', N'35.920007', N'74.313656', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (343, N'Chiniot', N'Punjab', N'31.72', N'72.978889', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (344, N'Sadiqabad', N'Punjab', N'28.30623', N'70.130646', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (345, N'Turbat', N'Balochistan', N'26.001224', N'63.048491', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (346, N'Dera Ismail Khan', N'Khyber Pakhtunkhwa', N'31.832691', N'70.902398', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (347, N'Chaman', N'Balochistan', N'30.917689', N'66.45259', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (348, N'Zhob', N'Balochistan', N'31.340817', N'69.449304', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (349, N'Mehra', N'Khyber Pakhtunkhwa', N'34.312817', N'73.220525', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (350, N'Parachinar', N'Federally Administered Tribal Areas', N'33.895672', N'70.098875', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (351, N'Gwadar', N'Balochistan', N'25.12163', N'62.325411', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (352, N'Kundian', N'Punjab', N'32.457747', N'71.478918', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (353, N'Shahdad Kot', N'Sindh', N'27.847263', N'67.906789', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (354, N'Haripur', N'Khyber Pakhtunkhwa', N'33.999967', N'72.934093', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (355, N'Matiari', N'Sindh', N'25.59709', N'68.4467', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (356, N'Dera Allahyar', N'Balochistan', N'28.373529', N'68.350778', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (357, N'Lodhran', N'15', N'29.540507', N'71.63357', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (358, N'Batgram', N'Khyber Pakhtunkhwa', N'34.679637', N'73.026299', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (359, N'Thatta', N'Sindh', N'24.747449', N'67.923528', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (360, N'Bagh', N'Azad Kashmir', N'33.981106', N'73.776084', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (361, N'Badin', N'Sindh', N'24.655995', N'68.836997', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (362, N'Mansehra', N'Khyber Pakhtunkhwa', N'34.330232', N'73.196788', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (363, N'Ziarat', N'Balochistan', N'30.382444', N'67.725624', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (364, N'Muzaffargarh', N'Punjab', N'30.072576', N'71.193788', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (365, N'Tando Allahyar', N'Sindh', N'25.462626', N'68.719233', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (366, N'Dera Murad Jamali', N'Balochistan', N'28.546568', N'68.223081', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (367, N'Karak', N'Khyber Pakhtunkhwa', N'33.116334', N'71.093536', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (368, N'Mardan', N'Khyber Pakhtunkhwa', N'34.197943', N'72.04965', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (369, N'Uthal', N'Balochistan', N'25.807222', N'66.621944', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (370, N'Nankana Sahib', N'Punjab', N'31.4475', N'73.697222', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (371, N'Barkhan', N'Balochistan', N'29.897727', N'69.525584', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (372, N'Hafizabad', N'Punjab', N'32.067857', N'73.685449', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (373, N'Kotli', N'Azad Kashmir', N'33.518362', N'73.902203', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (374, N'Loralai', N'Balochistan', N'30.370512', N'68.597949', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (375, N'Dera Bugti', N'Balochistan', N'29.036188', N'69.158493', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (376, N'Jhang City', N'Punjab', N'31.305684', N'72.325941', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (377, N'Sahiwal', N'Punjab', N'30.666667', N'73.1', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (378, N'Sanghar', N'Sindh', N'26.046558', N'68.9481', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (379, N'Pakpattan', N'Punjab', N'30.341044', N'73.386642', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (380, N'Chakwal', N'Punjab', N'32.933376', N'72.858531', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (381, N'Khushab', N'Punjab', N'32.296667', N'72.3525', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (382, N'Ghotki', N'Sindh', N'28.00604', N'69.316077', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (383, N'Kohlu', N'Balochistan', N'29.896505', N'69.253235', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (384, N'Khuzdar', N'Balochistan', N'27.738385', N'66.643365', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (385, N'Awaran', N'Balochistan', N'26.456768', N'65.231436', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (386, N'Nowshera', N'Khyber Pakhtunkhwa', N'34.015828', N'71.981232', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (387, N'Charsadda', N'Khyber Pakhtunkhwa', N'34.148221', N'71.740604', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (388, N'Qila Abdullah', N'Balochistan', N'30.728035', N'66.661174', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (389, N'Bahawalnagar', N'Punjab', N'29.998659', N'73.253604', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (390, N'Dadu', N'Sindh', N'26.730334', N'67.776896', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (391, N'Aliabad', N'Gilgit-Baltistan', N'36.307028', N'74.615449', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (392, N'Lakki Marwat', N'Khyber Pakhtunkhwa', N'32.607953', N'70.911416', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (393, N'Chilas', N'Gilgit-Baltistan', N'35.412867', N'74.104068', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (394, N'Pishin', N'Balochistan', N'30.581762', N'66.994061', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (395, N'Tank', N'Khyber Pakhtunkhwa', N'32.217071', N'70.383154', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (396, N'Chitral', N'Khyber Pakhtunkhwa', N'35.851802', N'71.786358', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (397, N'Qila Saifullah', N'Balochistan', N'30.700766', N'68.359843', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (398, N'Shikarpur', N'Sindh', N'27.957057', N'68.637886', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (399, N'Panjgur', N'Balochistan', N'26.971861', N'64.094594', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (400, N'Mastung', N'Balochistan', N'29.799656', N'66.845527', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (401, N'Kalat', N'Balochistan', N'29.026629', N'66.593607', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (402, N'Gandava', N'Balochistan', N'28.613207', N'67.485643', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (403, N'Khanewal', N'Punjab', N'30.301731', N'71.932124', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (404, N'Narowal', N'Punjab', N'32.1', N'74.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (405, N'Khairpur', N'Sindh', N'27.529483', N'68.761698', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (406, N'Malakand', N'Khyber Pakhtunkhwa', N'34.565609', N'71.930432', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (407, N'Vihari', N'Punjab', N'30.033333', N'72.35', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (408, N'Saidu Sharif', N'Khyber Pakhtunkhwa', N'34.746548', N'72.355675', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (409, N'Jhelum', N'Punjab', N'32.934484', N'73.731018', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (410, N'Mandi Bahauddin', N'Punjab', N'32.587037', N'73.491231', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (411, N'Bhakkar', N'Punjab', N'31.625247', N'71.06574', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (412, N'Toba Tek Singh', N'Punjab', N'30.974326', N'72.482694', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (413, N'Jamshoro', N'Sindh', N'25.436078', N'68.280172', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (414, N'Kharan', N'Balochistan', N'28.584585', N'65.415007', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (415, N'Umarkot', N'Sindh', N'25.36157', N'69.736241', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (416, N'Hangu', N'Khyber Pakhtunkhwa', N'33.53198', N'71.059499', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (417, N'Timargara', N'Khyber Pakhtunkhwa', N'34.826595', N'71.844226', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (418, N'Gakuch', N'Gilgit-Baltistan', N'36.176826', N'73.763834', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (419, N'Jacobabad', N'Sindh', N'28.281873', N'68.437613', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (420, N'Alpurai', N'Khyber Pakhtunkhwa', N'34.920577', N'72.632556', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (421, N'Mianwali', N'Punjab', N'32.574095', N'71.526386', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (422, N'Musa Khel Bazar', N'Balochistan', N'30.859443', N'69.82208', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (423, N'Naushahro Firoz', N'Sindh', N'26.840104', N'68.122651', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (424, N'New Mirpur', N'Azad Kashmir', N'33.147815', N'73.751867', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (425, N'Daggar', N'Khyber Pakhtunkhwa', N'34.511059', N'72.484375', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (426, N'Eidgah', N'Gilgit-Baltistan', N'35.347115', N'74.856317', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (427, N'Sibi', N'Balochistan', N'29.542989', N'67.87726', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (428, N'Dalbandin', N'Balochistan', N'28.888456', N'64.406156', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (429, N'Rajanpur', N'Punjab', N'29.103513', N'70.325038', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (430, N'Leiah', N'Punjab', N'30.961279', N'70.939043', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (431, N'Upper Dir', N'Khyber Pakhtunkhwa', N'35.207398', N'71.876801', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (432, N'Tando Muhammad Khan', N'Sindh', N'25.123007', N'68.535773', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (433, N'Attock City', N'Punjab', N'33.76671', N'72.359766', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (434, N'Rawala Kot', N'Azad Kashmir', N'33.857816', N'73.760426', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (435, N'Swabi', N'Khyber Pakhtunkhwa', N'34.120181', N'72.46982', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (436, N'Kandhkot', N'Sindh', N'28.243963', N'69.182354', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (437, N'Dasu', N'Khyber Pakhtunkhwa', N'35.291687', N'73.290602', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (438, N'Athmuqam', N'Azad Kashmir', N'34.571733', N'73.897236', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (439, N'Toronto', N'Ontario', N'43.666667', N'-79.416667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (440, N'Montréal', N'Québec', N'45.5', N'-73.583333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (441, N'Vancouver', N'British Columbia', N'49.25', N'-123.133333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (442, N'Ottawa', N'Ontario', N'45.416667', N'-75.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (443, N'Calgary', N'Alberta', N'51.083333', N'-114.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (444, N'Edmonton', N'Alberta', N'53.55', N'-113.5', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (445, N'Hamilton', N'Ontario', N'43.256101', N'-79.857484', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (446, N'Winnipeg', N'Manitoba', N'49.883333', N'-97.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (447, N'Québec', N'Québec', N'46.8', N'-71.25', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (448, N'Oshawa', N'Ontario', N'43.9', N'-78.866667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (449, N'Kitchener', N'Ontario', N'43.446976', N'-80.472484', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (450, N'Halifax', N'Nova Scotia', N'44.65', N'-63.6', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (451, N'London', N'Ontario', N'42.983333', N'-81.25', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (452, N'Windsor', N'Ontario', N'42.301649', N'-83.030744', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (453, N'Victoria', N'British Columbia', N'48.450234', N'-123.343529', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (454, N'Saskatoon', N'Saskatchewan', N'52.133333', N'-106.666667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (455, N'Barrie', N'Ontario', N'44.383333', N'-79.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (456, N'Regina', N'Saskatchewan', N'50.45', N'-104.616667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (457, N'Sudbury', N'Ontario', N'46.5', N'-80.966667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (458, N'Abbotsford', N'British Columbia', N'49.05', N'-122.3', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (459, N'Sarnia', N'Ontario', N'42.978417', N'-82.388177', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (460, N'Sherbrooke', N'Québec', N'45.4', N'-71.9', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (461, N'Saint John’s', N'Newfoundland and Labrador', N'47.55', N'-52.666667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (462, N'Kelowna', N'British Columbia', N'49.9', N'-119.483333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (463, N'Trois-Rivières', N'Québec', N'46.35', N'-72.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (464, N'Kingston', N'Ontario', N'44.3', N'-76.566667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (465, N'Thunder Bay', N'Ontario', N'48.4', N'-89.233333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (466, N'Moncton', N'New Brunswick', N'46.09652', N'-64.79757', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (467, N'Saint John', N'New Brunswick', N'45.230798', N'-66.095316', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (468, N'Nanaimo', N'British Columbia', N'49.15', N'-123.916667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (469, N'Peterborough', N'Ontario', N'44.3', N'-78.333333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (470, N'Saint-Jérôme', N'Québec', N'45.766667', N'-74', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (471, N'Red Deer', N'Alberta', N'52.266667', N'-113.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (472, N'Lethbridge', N'Alberta', N'49.7', N'-112.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (473, N'Kamloops', N'British Columbia', N'50.666667', N'-120.333333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (474, N'Prince George', N'British Columbia', N'53.916667', N'-122.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (475, N'Medicine Hat', N'Alberta', N'50.033333', N'-110.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (476, N'Drummondville', N'Québec', N'45.883333', N'-72.483333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (477, N'Chicoutimi', N'Québec', N'48.45', N'-71.066667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (478, N'Fredericton', N'New Brunswick', N'45.910648', N'-66.658649', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (479, N'Chilliwack', N'British Columbia', N'49.166667', N'-121.95', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (480, N'North Bay', N'Ontario', N'46.3', N'-79.45', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (481, N'Shawinigan-Sud', N'Québec', N'46.528557', N'-72.751453', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (482, N'Cornwall', N'Ontario', N'45.016667', N'-74.733333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (483, N'Joliette', N'Québec', N'46.034', N'-73.441', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (484, N'Belleville', N'Ontario', N'44.166667', N'-77.383333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (485, N'Charlottetown', N'Prince Edward Island', N'46.238225', N'-63.139481', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (486, N'Victoriaville', N'Québec', N'46.063106', N'-71.958802', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (487, N'Grande Prairie', N'Alberta', N'55.166667', N'-118.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (488, N'Penticton', N'British Columbia', N'49.5', N'-119.583333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (489, N'Sydney', N'Nova Scotia', N'46.15', N'-60.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (490, N'Orillia', N'Ontario', N'44.6', N'-79.416667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (491, N'Rimouski', N'Québec', N'48.433333', N'-68.516667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (492, N'Timmins', N'Ontario', N'48.466667', N'-81.333333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (493, N'Prince Albert', N'Saskatchewan', N'53.2', N'-105.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (494, N'Campbell River', N'British Columbia', N'50.016667', N'-125.25', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (495, N'Courtenay', N'British Columbia', N'49.683333', N'-125', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (496, N'Orangeville', N'Ontario', N'43.916366', N'-80.096671', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (497, N'Moose Jaw', N'Saskatchewan', N'50.4', N'-105.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (498, N'Brandon', N'Manitoba', N'49.833333', N'-99.95', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (499, N'Brockville', N'Ontario', N'44.594958', N'-75.682133', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (500, N'Saint-Georges', N'Québec', N'46.116667', N'-70.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (501, N'Sept-Îles', N'Québec', N'50.2', N'-66.383333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (502, N'Rouyn-Noranda', N'Québec', N'48.25', N'-79.016667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (503, N'Whitehorse', N'Yukon', N'60.716667', N'-135.05', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (504, N'Owen Sound', N'Ontario', N'44.566667', N'-80.85', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (505, N'Fort McMurray', N'Alberta', N'56.733333', N'-111.383333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (506, N'Corner Brook', N'Newfoundland and Labrador', N'48.95', N'-57.933333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (507, N'Val-d’Or', N'Québec', N'48.116667', N'-77.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (508, N'New Glasgow', N'Nova Scotia', N'45.583333', N'-62.633333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (509, N'Terrace', N'British Columbia', N'54.5', N'-128.583333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (510, N'North Battleford', N'Saskatchewan', N'52.766667', N'-108.283333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (511, N'Yellowknife', N'Northwest Territories', N'62.45', N'-114.35', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (512, N'Fort Saint John', N'British Columbia', N'56.25', N'-120.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (513, N'Cranbrook', N'British Columbia', N'49.516667', N'-115.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (514, N'Edmundston', N'New Brunswick', N'47.36226', N'-68.327874', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (515, N'Rivière-du-Loup', N'Québec', N'47.833333', N'-69.533333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (516, N'Camrose', N'Alberta', N'53.016667', N'-112.816667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (517, N'Pembroke', N'Ontario', N'45.816667', N'-77.116667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (518, N'Yorkton', N'Saskatchewan', N'51.216667', N'-102.466667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (519, N'Swift Current', N'Saskatchewan', N'50.283333', N'-107.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (520, N'Prince Rupert', N'British Columbia', N'54.316667', N'-130.333333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (521, N'Williams Lake', N'British Columbia', N'52.116667', N'-122.15', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (522, N'Brooks', N'Alberta', N'50.566667', N'-111.9', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (523, N'Quesnel', N'British Columbia', N'52.983333', N'-122.483333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (524, N'Thompson', N'Manitoba', N'55.75', N'-97.866667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (525, N'Dolbeau', N'Québec', N'48.866667', N'-72.233333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (526, N'Powell River', N'British Columbia', N'49.883333', N'-124.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (527, N'Wetaskiwin', N'Alberta', N'52.966667', N'-113.383333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (528, N'Nelson', N'British Columbia', N'49.483333', N'-117.283333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (529, N'Mont-Laurier', N'Québec', N'46.55', N'-75.5', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (530, N'Kenora', N'Ontario', N'49.766667', N'-94.466667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (531, N'Dawson Creek', N'British Columbia', N'55.766667', N'-120.233333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (532, N'Amos', N'Québec', N'48.566667', N'-78.116667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (533, N'Baie-Comeau', N'Québec', N'49.216667', N'-68.15', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (534, N'Hinton', N'Alberta', N'53.4', N'-117.583333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (535, N'Selkirk', N'Manitoba', N'50.15', N'-96.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (536, N'Steinbach', N'Manitoba', N'49.516667', N'-96.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (537, N'Weyburn', N'Saskatchewan', N'49.666667', N'-103.85', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (538, N'Amherst', N'Nova Scotia', N'45.830019', N'-64.210024', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (539, N'Kapuskasing', N'Ontario', N'49.416667', N'-82.433333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (540, N'Dauphin', N'Manitoba', N'51.15', N'-100.05', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (541, N'Dryden', N'Ontario', N'49.783333', N'-92.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (542, N'Revelstoke', N'British Columbia', N'51', N'-118.183333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (543, N'Happy Valley', N'Newfoundland and Labrador', N'53.3', N'-60.3', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (544, N'Banff', N'Alberta', N'51.166667', N'-115.566667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (545, N'Yarmouth', N'Nova Scotia', N'43.833965', N'-66.113926', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (546, N'La Sarre', N'Québec', N'48.8', N'-79.2', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (547, N'Parry Sound', N'Ontario', N'45.333333', N'-80.033333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (548, N'Stephenville', N'Newfoundland and Labrador', N'48.55', N'-58.566667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (549, N'Antigonish', N'Nova Scotia', N'45.616667', N'-61.966667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (550, N'Flin Flon', N'Manitoba', N'54.766667', N'-101.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (551, N'Fort Nelson', N'British Columbia', N'58.816667', N'-122.533333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (552, N'Smithers', N'British Columbia', N'54.766667', N'-127.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (553, N'Iqaluit', N'Nunavut', N'63.733333', N'-68.5', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (554, N'Bathurst', N'New Brunswick', N'47.558376', N'-65.656517', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (555, N'The Pas', N'Manitoba', N'53.816667', N'-101.233333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (556, N'Norway House', N'Manitoba', N'53.966667', N'-97.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (557, N'Meadow Lake', N'Saskatchewan', N'54.129722', N'-108.434722', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (558, N'Vegreville', N'Alberta', N'53.5', N'-112.05', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (559, N'Stettler', N'Alberta', N'52.333333', N'-112.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (560, N'Peace River', N'Alberta', N'56.233333', N'-117.283333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (561, N'New Liskeard', N'Ontario', N'47.5', N'-79.666667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (562, N'Hearst', N'Ontario', N'49.7', N'-83.666667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (563, N'Creston', N'British Columbia', N'49.1', N'-116.516667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (564, N'Marathon', N'Ontario', N'48.75', N'-86.366667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (565, N'Cochrane', N'Ontario', N'49.066667', N'-81.016667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (566, N'Kindersley', N'Saskatchewan', N'51.466667', N'-109.133333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (567, N'Liverpool', N'Nova Scotia', N'44.038414', N'-64.718433', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (568, N'Melville', N'Saskatchewan', N'50.933333', N'-102.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (569, N'Channel-Port aux Basques', N'Newfoundland and Labrador', N'47.566667', N'-59.15', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (570, N'Deer Lake', N'Newfoundland and Labrador', N'49.183333', N'-57.433333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (571, N'Saint-Augustin', N'Québec', N'51.233333', N'-58.65', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (572, N'Digby', N'Nova Scotia', N'44.578466', N'-65.783525', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (573, N'Jasper', N'Alberta', N'52.883333', N'-118.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (574, N'Hay River', N'Northwest Territories', N'60.85', N'-115.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (575, N'Windsor', N'Nova Scotia', N'44.958995', N'-64.144786', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (576, N'La Ronge', N'Saskatchewan', N'55.1', N'-105.3', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (577, N'Deer Lake', N'Ontario', N'52.616667', N'-94.066667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (578, N'Gaspé', N'Québec', N'48.833333', N'-64.483333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (579, N'Atikokan', N'Ontario', N'48.75', N'-91.616667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (580, N'Gander', N'Newfoundland and Labrador', N'48.95', N'-54.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (581, N'Fort Chipewyan', N'Alberta', N'58.716667', N'-111.15', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (582, N'Shelburne', N'Nova Scotia', N'43.753356', N'-65.246074', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (583, N'Inuvik', N'Northwest Territories', N'68.35', N'-133.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (584, N'Lac La Biche', N'Alberta', N'54.771944', N'-111.964722', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (585, N'Lillooet', N'British Columbia', N'50.683333', N'-121.933333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (586, N'Chapleau', N'Ontario', N'47.833333', N'-83.4', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (587, N'Burns Lake', N'British Columbia', N'54.216667', N'-125.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (588, N'Gimli', N'Manitoba', N'50.633333', N'-97', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (589, N'Athabasca', N'Alberta', N'54.716667', N'-113.266667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (590, N'Nelson House', N'Manitoba', N'55.8', N'-98.85', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (591, N'Rankin Inlet', N'Nunavut', N'62.816667', N'-92.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (592, N'Port Hardy', N'British Columbia', N'50.716667', N'-127.5', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (593, N'Biggar', N'Saskatchewan', N'52.05', N'-107.983333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (594, N'Wiarton', N'Ontario', N'44.733333', N'-81.133333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (595, N'Wawa', N'Ontario', N'47.99473', N'-84.77002', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (596, N'Hudson Bay', N'Saskatchewan', N'52.85', N'-102.383333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (597, N'Matagami', N'Québec', N'49.75', N'-77.633333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (598, N'Arviat', N'Nunavut', N'61.116667', N'-94.05', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (599, N'Attawapiskat', N'Ontario', N'52.916667', N'-82.433333', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (600, N'Red Lake', N'Ontario', N'51.033333', N'-93.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (601, N'Moosonee', N'Ontario', N'51.266667', N'-80.65', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (602, N'Tofino', N'British Columbia', N'49.133333', N'-125.9', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (603, N'Igloolik', N'Nunavut', N'69.4', N'-81.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (604, N'Inukjuak', N'Québec', N'58.45334', N'-78.102493', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (605, N'Little Current', N'Ontario', N'45.966667', N'-81.933333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (606, N'Baker Lake', N'Nunavut', N'64.316667', N'-96.016667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (607, N'Pond Inlet', N'Nunavut', N'72.7', N'-78', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (608, N'Cap-Chat', N'Québec', N'49.083333', N'-66.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (609, N'Cambridge Bay', N'Nunavut', N'69.116667', N'-105.033333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (610, N'Thessalon', N'Ontario', N'46.25', N'-83.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (611, N'New Bella Bella', N'British Columbia', N'52.166667', N'-128.133333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (612, N'Cobalt', N'Ontario', N'47.383333', N'-79.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (613, N'Cape Dorset', N'Nunavut', N'64.233333', N'-76.55', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (614, N'Pangnirtung', N'Nunavut', N'66.133333', N'-65.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (615, N'West Dawson', N'Yukon', N'64.066667', N'-139.45', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (616, N'Kugluktuk', N'Nunavut', N'67.833333', N'-115.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (617, N'Geraldton', N'Ontario', N'49.716667', N'-86.966667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (618, N'Gillam', N'Manitoba', N'56.35', N'-94.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (619, N'Kuujjuaq', N'Québec', N'58.1', N'-68.4', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (620, N'Lake Louise', N'Alberta', N'51.433333', N'-116.183333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (621, N'Nipigon', N'Ontario', N'49.016667', N'-88.25', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (622, N'Nain', N'Newfoundland and Labrador', N'56.55', N'-61.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (623, N'Gjoa Haven', N'Nunavut', N'68.633333', N'-95.916667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (624, N'Fort McPherson', N'Northwest Territories', N'67.433333', N'-134.866667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (625, N'Argentia', N'Newfoundland and Labrador', N'47.3', N'-54', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (626, N'Norman Wells', N'Northwest Territories', N'65.283333', N'-126.85', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (627, N'Churchill', N'Manitoba', N'58.766667', N'-94.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (628, N'Repulse Bay', N'Nunavut', N'66.516667', N'-86.233333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (629, N'Tuktoyaktuk', N'Northwest Territories', N'69.45', N'-133.066667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (630, N'Berens River', N'Manitoba', N'52.366667', N'-97.033333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (631, N'Shamattawa', N'Manitoba', N'55.85', N'-92.083333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (632, N'Baddeck', N'Nova Scotia', N'46.1', N'-60.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (633, N'Coral Harbour', N'Nunavut', N'64.133333', N'-83.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (634, N'La Scie', N'Newfoundland and Labrador', N'49.966667', N'-55.583333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (635, N'Watson Lake', N'Yukon', N'60.116667', N'-128.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (636, N'Taloyoak', N'Nunavut', N'69.533333', N'-93.533333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (637, N'Natashquan', N'Québec', N'50.183333', N'-61.816667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (638, N'Buchans', N'Newfoundland and Labrador', N'48.816667', N'-56.866667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (639, N'Hall Beach', N'Nunavut', N'68.766667', N'-81.2', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (640, N'Arctic Bay', N'Nunavut', N'73.033333', N'-85.166667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (641, N'Fort Good Hope', N'Northwest Territories', N'66.266667', N'-128.633333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (642, N'Mingan', N'Québec', N'50.3', N'-64.016667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (643, N'Kangirsuk', N'Québec', N'60.016667', N'-70.033333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (644, N'Sandspit', N'British Columbia', N'53.239111', N'-131.818769', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (645, N'Déline', N'Northwest Territories', N'65.183333', N'-123.416667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (646, N'Fort Smith', N'Northwest Territories', N'60', N'-111.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (647, N'Cartwright', N'Newfoundland and Labrador', N'53.7', N'-57.016667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (648, N'Holman', N'Northwest Territories', N'70.733333', N'-117.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (649, N'Lynn Lake', N'Manitoba', N'56.85', N'-101.05', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (650, N'Schefferville', N'Québec', N'54.8', N'-66.816667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (651, N'Trout River', N'Newfoundland and Labrador', N'49.483333', N'-58.116667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (652, N'Forteau Bay', N'Newfoundland and Labrador', N'51.45', N'-56.95', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (653, N'Fort Resolution', N'Northwest Territories', N'61.166667', N'-113.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (654, N'Hopedale', N'Newfoundland and Labrador', N'55.45', N'-60.216667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (655, N'Pukatawagan', N'Manitoba', N'55.733333', N'-101.316667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (656, N'Trepassey', N'Newfoundland and Labrador', N'46.733333', N'-53.366667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (657, N'Kimmirut', N'Nunavut', N'62.85', N'-69.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (658, N'Chesterfield Inlet', N'Nunavut', N'63.333333', N'-90.7', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (659, N'Eastmain', N'Québec', N'52.233333', N'-78.516667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (660, N'Dease Lake', N'British Columbia', N'58.476697', N'-129.96146', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (661, N'Paulatuk', N'Northwest Territories', N'69.383333', N'-123.983333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (662, N'Fort Simpson', N'Northwest Territories', N'61.85', N'-121.333333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (663, N'Brochet', N'Manitoba', N'57.883333', N'-101.666667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (664, N'Cat Lake', N'Ontario', N'51.716667', N'-91.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (665, N'Radisson', N'Québec', N'53.783333', N'-77.616667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (666, N'Port-Menier', N'Québec', N'49.816667', N'-64.35', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (667, N'Resolute', N'Nunavut', N'74.683333', N'-94.9', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (668, N'Saint Anthony', N'Newfoundland and Labrador', N'51.383333', N'-55.6', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (669, N'Port Hope Simpson', N'Newfoundland and Labrador', N'52.533333', N'-56.3', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (670, N'Oxford House', N'Manitoba', N'54.95', N'-95.266667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (671, N'Tsiigehtchic', N'Northwest Territories', N'67.433333', N'-133.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (672, N'Ivujivik', N'Québec', N'62.416667', N'-77.9', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (673, N'Stony Rapids', N'Saskatchewan', N'59.266667', N'-105.833333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (674, N'Alert', N'Nunavut', N'82.483333', N'-62.25', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (675, N'Fort Severn', N'Ontario', N'55.983333', N'-87.65', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (676, N'Rigolet', N'Newfoundland and Labrador', N'54.166667', N'-58.433333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (677, N'Lansdowne House', N'Ontario', N'52.216667', N'-87.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (678, N'Salluit', N'Québec', N'62.2', N'-75.633333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (679, N'Lutselk’e', N'Northwest Territories', N'62.4', N'-110.733333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (680, N'Uranium City', N'Saskatchewan', N'59.566667', N'-108.616667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (681, N'Burwash Landing', N'Yukon', N'61.35', N'-139', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (682, N'Grise Fiord', N'Nunavut', N'76.416667', N'-82.95', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (683, N'Big Beaverhouse', N'Ontario', N'52.95', N'-89.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (684, N'Island Lake', N'Manitoba', N'53.966667', N'-94.766667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (685, N'Ennadai', N'Nunavut', N'61.133333', N'-100.883333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (686, N'Mumbai', N'Maharashtra', N'18.987807', N'72.836447', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (687, N'Delhi', N'Delhi', N'28.651952', N'77.231495', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (688, N'Kolkata', N'West Bengal', N'22.562627', N'88.363044', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (689, N'Chennai', N'Tamil Nadu ', N'13.084622', N'80.248357', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (690, N'Bengaluru', N'Karnataka', N'12.977063', N'77.587106', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (691, N'Hyderabad', N'Andhra Pradesh', N'17.384052', N'78.456355', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (692, N'Ahmadabad', N'Gujarat', N'23.025793', N'72.587265', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (693, N'Haora', N'West Bengal', N'22.576882', N'88.318566', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (694, N'Pune', N'Maharashtra', N'18.513271', N'73.849852', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (695, N'Surat', N'Gujarat', N'21.195944', N'72.830232', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (696, N'Mardanpur', N'Uttar Pradesh', N'26.430066', N'80.267176', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (697, N'Rampura', N'Rajasthan', N'26.884682', N'75.789336', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (698, N'Lucknow', N'Uttar Pradesh', N'26.839281', N'80.923133', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (699, N'Nara', N'Maharashtra', N'21.203096', N'79.089284', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (700, N'Patna', N'Bihar', N'25.615379', N'85.101027', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (701, N'Indore', N'Madhya Pradesh', N'22.717736', N'75.85859', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (702, N'Vadodara', N'Gujarat', N'22.299405', N'73.208119', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (703, N'Bhopal', N'Madhya Pradesh', N'23.254688', N'77.402892', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (704, N'Coimbatore', N'Tamil Nadu ', N'11.005547', N'76.966122', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (705, N'Ludhiana', N'Punjab', N'30.912042', N'75.853789', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (706, N'agra', N'Uttar Pradesh', N'27.187935', N'78.003944', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (707, N'Kalyan', N'Maharashtra', N'19.243703', N'73.135537', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (708, N'Vishakhapatnam', N'Andhra Pradesh', N'17.704052', N'83.297663', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (709, N'Kochi', N'Kerala', N'9.947743', N'76.253802', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (710, N'Nasik', N'Maharashtra', N'19.999963', N'73.776887', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (711, N'Meerut', N'Uttar Pradesh', N'28.980018', N'77.706356', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (712, N'Faridabad', N'Haryana', N'28.411236', N'77.313162', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (713, N'Varanasi', N'Uttar Pradesh', N'25.31774', N'83.005811', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (714, N'Ghaziabad', N'Uttar Pradesh', N'28.665353', N'77.439148', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (715, N'asansol', N'West Bengal', N'23.683333', N'86.983333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (716, N'Jamshedpur', N'Jharkhand', N'22.802776', N'86.185448', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (717, N'Madurai', N'Tamil Nadu ', N'9.917347', N'78.119622', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (718, N'Jabalpur', N'Madhya Pradesh', N'23.174495', N'79.935903', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (719, N'Rajkot', N'Gujarat', N'22.291606', N'70.793217', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (720, N'Dhanbad', N'Jharkhand', N'23.801988', N'86.443244', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (721, N'Amritsar', N'Punjab', N'31.622337', N'74.875335', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (722, N'Warangal', N'Andhra Pradesh', N'17.978423', N'79.600209', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (723, N'Allahabad', N'Uttar Pradesh', N'25.44478', N'81.843217', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (724, N'Srinagar', N'Jammu and Kashmir', N'34.085652', N'74.805553', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (725, N'Aurangabad', N'Maharashtra', N'19.880943', N'75.346739', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (726, N'Bhilai', N'Chhattisgarh', N'21.209188', N'81.428497', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (727, N'Solapur', N'Maharashtra', N'17.671523', N'75.910437', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (728, N'Ranchi', N'Jharkhand', N'23.347768', N'85.338564', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (729, N'Jodhpur', N'Rajasthan', N'26.26841', N'73.005943', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (730, N'Guwahati', N'Assam', N'26.176076', N'91.762932', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (731, N'Chandigarh', N'Chandigarh', N'30.736292', N'76.788398', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (732, N'Gwalior', N'Madhya Pradesh', N'26.229825', N'78.173369', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (733, N'Thiruvananthapuram', N'Kerala', N'8.485498', N'76.949238', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (734, N'Tiruchchirappalli', N'Tamil Nadu ', N'10.815499', N'78.696513', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (735, N'Hubli', N'Karnataka', N'15.349955', N'75.138619', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (736, N'Mysore', N'Karnataka', N'12.292664', N'76.638543', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (737, N'Raipur', N'Chhattisgarh', N'21.233333', N'81.633333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (738, N'Salem', N'Tamil Nadu ', N'11.651165', N'78.158672', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (739, N'Bhubaneshwar', N'Odisha', N'20.272411', N'85.833853', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (740, N'Kota', N'Rajasthan', N'25.182544', N'75.839065', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (741, N'Jhansi', N'Uttar Pradesh', N'25.458872', N'78.579943', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (742, N'Bareilly', N'Uttar Pradesh', N'28.347023', N'79.421934', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (743, N'Aligarh', N'Uttar Pradesh', N'27.881453', N'78.07464', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (744, N'Bhiwandi', N'Maharashtra', N'19.300229', N'73.058813', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (745, N'Jammu', N'Jammu and Kashmir', N'32.735686', N'74.869112', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (746, N'Moradabad', N'Uttar Pradesh', N'28.838931', N'78.776838', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (747, N'Mangalore', N'Karnataka', N'12.865371', N'74.842432', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (748, N'Kolhapur', N'Maharashtra', N'16.695633', N'74.231669', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (749, N'Amravati', N'Maharashtra', N'20.933272', N'77.75152', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (750, N'Dehra Dun', N'Uttarakhand', N'30.324427', N'78.033922', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (751, N'Malegaon Camp', N'Maharashtra', N'20.569974', N'74.515415', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (752, N'Nellore', N'Andhra Pradesh', N'14.449918', N'79.986967', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (753, N'Gopalpur', N'Uttar Pradesh', N'26.735389', N'83.38064', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (754, N'Shimoga', N'Karnataka', N'13.932424', N'75.572555', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (755, N'Tiruppur', N'Tamil Nadu ', N'11.104096', N'77.346402', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (756, N'Raurkela', N'Odisha', N'22.224964', N'84.864143', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (757, N'Nanded', N'Maharashtra', N'19.160227', N'77.314971', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (758, N'Belgaum', N'Karnataka', N'15.862643', N'74.508534', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (759, N'Sangli', N'Maharashtra', N'16.856777', N'74.569196', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (760, N'Chanda', N'Maharashtra', N'19.950758', N'79.295229', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (761, N'Ajmer', N'Rajasthan', N'26.452103', N'74.638667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (762, N'Cuttack', N'Odisha', N'20.522922', N'85.78813', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (763, N'Bikaner', N'Rajasthan', N'28.017623', N'73.314955', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (764, N'Bhavnagar', N'Gujarat', N'21.774455', N'72.152496', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (765, N'Hisar', N'Haryana', N'29.153938', N'75.722944', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (766, N'Bilaspur', N'Chhattisgarh', N'22.080046', N'82.155431', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (767, N'Tirunelveli', N'Tamil Nadu ', N'8.725181', N'77.684519', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (768, N'Guntur', N'Andhra Pradesh', N'16.299737', N'80.457293', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (769, N'Shiliguri', N'West Bengal', N'26.710035', N'88.428512', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (770, N'Ujjain', N'Madhya Pradesh', N'23.182387', N'75.776433', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (771, N'Davangere', N'Karnataka', N'14.469237', N'75.92375', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (772, N'Akola', N'Maharashtra', N'20.709569', N'76.998103', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (773, N'Saharanpur', N'Uttar Pradesh', N'29.967896', N'77.545221', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (774, N'Gulbarga', N'Karnataka', N'17.335827', N'76.83757', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (775, N'Bhatpara', N'West Bengal', N'22.866431', N'88.401129', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (776, N'Dhulia', N'Maharashtra', N'20.901299', N'74.777373', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (777, N'Udaipur', N'Rajasthan', N'24.57951', N'73.690508', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (778, N'Bellary', N'Karnataka', N'15.142049', N'76.92398', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (779, N'Tuticorin', N'Tamil Nadu ', N'8.805038', N'78.151884', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (780, N'Kurnool', N'Andhra Pradesh', N'15.828865', N'78.036021', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (781, N'Gaya', N'Bihar', N'24.796858', N'85.003852', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (782, N'Sikar', N'Rajasthan', N'27.614778', N'75.138671', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (783, N'Tumkur', N'Karnataka', N'13.341358', N'77.102203', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (784, N'Kollam', N'Kerala', N'8.881131', N'76.584694', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (785, N'Ahmadnagar', N'Maharashtra', N'19.094571', N'74.738432', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (786, N'Bhilwara', N'Rajasthan', N'25.347071', N'74.640812', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (787, N'Nizamabad', N'Andhra Pradesh', N'18.673151', N'78.10008', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (788, N'Parbhani', N'Maharashtra', N'19.268553', N'76.770807', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (789, N'Shillong', N'Meghalaya', N'25.573987', N'91.896807', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (790, N'Latur', N'Maharashtra', N'18.399487', N'76.584252', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (791, N'Rajapalaiyam', N'Tamil Nadu ', N'9.451111', N'77.556121', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (792, N'Bhagalpur', N'Bihar', N'25.244462', N'86.971832', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (793, N'Muzaffarnagar', N'Uttar Pradesh', N'29.470914', N'77.703324', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (794, N'Muzaffarpur', N'Bihar', N'26.122593', N'85.390553', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (795, N'Mathura', N'Uttar Pradesh', N'27.503501', N'77.672145', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (796, N'Patiala', N'Punjab', N'30.336245', N'76.392199', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (797, N'Saugor', N'Madhya Pradesh', N'23.838766', N'78.738738', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (798, N'Brahmapur', N'Odisha', N'19.311514', N'84.792903', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (799, N'Shahbazpur', N'Uttar Pradesh', N'27.874116', N'79.879327', NULL)
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (800, N'New Delhi', N'Delhi', N'28.6', N'77.2', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (801, N'Rohtak', N'Haryana', N'28.894473', N'76.589166', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (802, N'Samlaipadar', N'Odisha', N'21.478072', N'83.990505', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (803, N'Ratlam', N'Madhya Pradesh', N'23.330331', N'75.040315', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (804, N'Firozabad', N'Uttar Pradesh', N'27.150917', N'78.397808', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (805, N'Rajahmundry', N'Andhra Pradesh', N'17.005171', N'81.777839', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (806, N'Barddhaman', N'West Bengal', N'23.255716', N'87.856906', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (807, N'Bidar', N'Karnataka', N'17.913309', N'77.530105', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (808, N'Bamanpuri', N'Uttar Pradesh', N'28.804495', N'79.040305', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (809, N'Kakinada', N'Andhra Pradesh', N'16.960361', N'82.238086', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (810, N'Panipat', N'Haryana', N'29.387471', N'76.968246', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (811, N'Khammam', N'Andhra Pradesh', N'17.247672', N'80.143682', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (812, N'Bhuj', N'Gujarat', N'23.253972', N'69.669281', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (813, N'Karimnagar', N'Andhra Pradesh', N'18.436738', N'79.13222', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (814, N'Tirupati', N'Andhra Pradesh', N'13.635505', N'79.419888', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (815, N'Hospet', N'Karnataka', N'15.269537', N'76.387103', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (816, N'Chikka Mandya', N'Karnataka', N'12.545602', N'76.895078', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (817, N'Alwar', N'Rajasthan', N'27.566291', N'76.610202', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (818, N'Aizawl', N'Mizoram', N'23.736701', N'92.714596', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (819, N'Bijapur', N'Karnataka', N'16.827715', N'75.718988', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (820, N'Imphal', N'Manipur', N'24.808053', N'93.944203', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (821, N'Tharati Etawah', N'Uttar Pradesh', N'26.758236', N'79.014875', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (822, N'Raichur', N'Karnataka', N'16.205459', N'77.35567', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (823, N'Pathankot', N'Punjab', N'32.274842', N'75.652865', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (824, N'Chirala', N'Andhra Pradesh', N'15.823849', N'80.352187', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (825, N'Sonipat', N'Haryana', N'28.994778', N'77.019375', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (826, N'Mirzapur', N'Uttar Pradesh', N'25.144902', N'82.565335', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (827, N'Hapur', N'Uttar Pradesh', N'28.729845', N'77.780681', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (828, N'Porbandar', N'Gujarat', N'21.641346', N'69.600868', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (829, N'Bharatpur', N'Rajasthan', N'27.215251', N'77.492786', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (830, N'Puducherry', N'Puducherry', N'11.933812', N'79.829792', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (831, N'Karnal', N'Haryana', N'29.691971', N'76.984483', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (832, N'Nagercoil', N'Tamil Nadu ', N'8.177313', N'77.43437', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (833, N'Thanjavur', N'Tamil Nadu ', N'10.785233', N'79.139093', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (834, N'Pali', N'Rajasthan', N'25.775125', N'73.320611', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (835, N'Agartala', N'Tripura', N'23.836049', N'91.279386', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (836, N'Ongole', N'Andhra Pradesh', N'15.503565', N'80.044541', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (837, N'Puri', N'Odisha', N'19.798254', N'85.824938', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (838, N'Dindigul', N'Tamil Nadu ', N'10.362853', N'77.975827', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (839, N'Haldia', N'West Bengal', N'22.025278', N'88.058333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (840, N'Bulandshahr', N'Uttar Pradesh', N'28.403922', N'77.857731', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (841, N'Purnea', N'Bihar', N'25.776703', N'87.473655', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (842, N'Proddatur', N'Andhra Pradesh', N'14.7502', N'78.548129', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (843, N'Gurgaon', N'Haryana', N'28.460105', N'77.026352', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (844, N'Khanapur', N'Maharashtra', N'21.273716', N'76.117376', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (845, N'Machilipatnam', N'Andhra Pradesh', N'16.187466', N'81.13888', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (846, N'Bhiwani', N'Haryana', N'28.793044', N'76.13968', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (847, N'Nandyal', N'Andhra Pradesh', N'15.477994', N'78.483605', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (848, N'Bhusaval', N'Maharashtra', N'21.043649', N'75.785058', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (849, N'Bharauri', N'Uttar Pradesh', N'27.598203', N'81.694709', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (850, N'Tonk', N'Rajasthan', N'26.168672', N'75.786111', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (851, N'Sirsa', N'Haryana', N'29.534893', N'75.028981', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (852, N'Vizianagaram', N'Andhra Pradesh', N'18.11329', N'83.397743', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (853, N'Vellore', N'Tamil Nadu ', N'12.905769', N'79.137104', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (854, N'Alappuzha', N'Kerala', N'9.494647', N'76.331108', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (855, N'Shimla', N'Himachal Pradesh', N'31.104423', N'77.166623', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (856, N'Hindupur', N'Andhra Pradesh', N'13.828065', N'77.491425', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (857, N'Baramula', N'Jammu and Kashmir', N'34.209004', N'74.342853', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (858, N'Bakshpur', N'Uttar Pradesh', N'25.894283', N'80.792104', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (859, N'Dibrugarh', N'Assam', N'27.479888', N'94.90837', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (860, N'Saidapur', N'Uttar Pradesh', N'27.598784', N'80.75089', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (861, N'Navsari', N'Gujarat', N'20.85', N'72.916667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (862, N'Budaun', N'Uttar Pradesh', N'28.038114', N'79.126677', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (863, N'Cuddalore', N'Tamil Nadu ', N'11.746289', N'79.764362', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (864, N'Haripur', N'Punjab', N'31.463218', N'75.986418', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (865, N'Krishnapuram', N'Tamil Nadu ', N'12.869617', N'79.719469', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (866, N'Fyzabad', N'Uttar Pradesh', N'26.775486', N'82.150182', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (867, N'Silchar', N'Assam', N'24.827327', N'92.797868', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (868, N'Ambala', N'Haryana', N'30.360993', N'76.797819', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (869, N'Krishnanagar', N'West Bengal', N'23.405761', N'88.490733', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (870, N'Kolar', N'Karnataka', N'13.137679', N'78.129989', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (871, N'Kumbakonam', N'Tamil Nadu ', N'10.959789', N'79.377472', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (872, N'Tiruvannamalai', N'Tamil Nadu ', N'12.230204', N'79.072954', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (873, N'Pilibhit', N'Uttar Pradesh', N'28.631245', N'79.804362', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (874, N'Abohar', N'Punjab', N'30.144533', N'74.19552', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (875, N'Port Blair', N'Andaman and Nicobar Islands', N'11.666667', N'92.75', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (876, N'Alipur Duar', N'West Bengal', N'26.4835', N'89.522855', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (877, N'Hatisa', N'Uttar Pradesh', N'27.592698', N'78.013843', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (878, N'Valparai', N'Tamil Nadu ', N'10.325163', N'76.955299', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (879, N'Aurangabad', N'Bihar', N'24.752037', N'84.374202', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (880, N'Kohima', N'Nagaland', N'25.674673', N'94.110988', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (881, N'Gangtok', N'Sikkim', N'27.325739', N'88.612155', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (882, N'Karur', N'Tamil Nadu ', N'10.960277', N'78.076753', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (883, N'Jorhat', N'Assam', N'26.757509', N'94.203055', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (884, N'Panaji', N'Goa', N'15.498289', N'73.824541', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (885, N'Saidpur', N'Jammu and Kashmir', N'34.318174', N'74.457093', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (886, N'Tezpur', N'Assam', N'26.633333', N'92.8', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (887, N'Itanagar', N'Arunachal Pradesh', N'27.102349', N'93.692047', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (888, N'Daman', N'Daman and Diu', N'20.414315', N'72.83236', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (889, N'Silvassa', N'Dadra and Nagar Haveli', N'20.273855', N'72.996728', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (890, N'Diu', N'Daman and Diu', N'20.715115', N'70.987952', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (891, N'Dispur', N'Assam', N'26.135638', N'91.800688', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (892, N'Kavaratti', N'Lakshadweep', N'10.566667', N'72.616667', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (893, N'Calicut', N'Kerala', N'11.248016', N'75.780402', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (894, N'Kagaznagar', N'Andhra Pradesh', N'19.331589', N'79.466051', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (895, N'Jaipur', N'Rajasthan', N'26.913312', N'75.787872', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (896, N'Ghandinagar', N'Gujarat', N'23.216667', N'72.683333', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (897, N'Panchkula', N'Haryana', N'30.691512', N'76.853736', NULL)
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (898, N'New York', N' New York', N'40.6635', N'-73.9387', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (899, N'Los Angeles', N' California', N'34.0194', N'-118.4108', N'United States')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (900, N'Chicago', N' Illinois', N'41.8376', N'-87.6818', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (901, N'Houston', N' Texas', N'29.7866', N'-95.3909', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (902, N'Phoenix', N' Arizona', N'33.5722', N'-112.0901', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (903, N'Philadelphia', N' Pennsylvania', N'40.0094', N'-75.1333', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (904, N'San Antonio', N' Texas', N'29.4724', N'-98.5251', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (905, N'San Diego', N' California', N'32.8153', N'-117.135', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (906, N'Dallas', N' Texas', N'32.7933', N'-96.7665', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (907, N'San Jose', N' California', N'37.2967', N'-121.8189', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (908, N'Austin', N' Texas', N'30.3039', N'-97.7544', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (909, N'Jacksonville', N' Florida', N'30.3369', N'-81.6616', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (910, N'San Francisco', N' California', N'37.7272', N'-123.0322', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (911, N'Columbus', N' Ohio', N'39.9852', N'-82.9848', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (912, N'Fort Worth', N' Texas', N'32.7815', N'-97.3467', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (913, N'Indianapolis', N' Indiana', N'39.7767', N'-86.1459', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (914, N'Charlotte', N' North Carolina', N'35.2078', N'-80.831', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (915, N'Seattle', N' Washington', N'47.6205', N'-122.3509', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (916, N'Denver', N' Colorado', N'39.7619', N'-104.8811', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (917, N'Washington', N' District of Columbia', N'38.9041', N'-77.0172', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (918, N'Boston', N' Massachusetts', N'42.332', N'-71.0202', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (919, N'El Paso', N' Texas', N'31.8484', N'-106.427', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (920, N'Detroit', N' Michigan', N'42.383', N'-83.1022', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (921, N'Nashville', N' Tennessee', N'36.1718', N'-86.785', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (922, N'Memphis', N' Tennessee', N'35.1028', N'-89.9774', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (923, N'Portland', N' Oregon', N'45.537', N'-122.65', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (924, N'Oklahoma', N' Oklahoma', N'35.4671', N'-97.5137', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (925, N'Las Vegas', N' Nevada', N'36.2292', N'-115.2601', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (926, N'Louisville', N' Kentucky', N'38.1654', N'-85.6474', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (927, N'Baltimore', N' Maryland', N'39.3', N'-76.6105', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (928, N'Milwaukee', N' Wisconsin', N'43.0633', N'-87.9667', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (929, N'Albuquerque', N' New Mexico', N'35.1056', N'-106.6474', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (930, N'Tucson', N' Arizona', N'32.1531', N'-110.8706', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (931, N'Fresno', N' California', N'36.7836', N'-119.7934', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (932, N'Sacramento', N' California', N'38.5666', N'-121.4686', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (933, N'Mesa', N' Arizona', N'33.4019', N'-111.7174', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (934, N'Kansas', N' Missouri', N'39.1251', N'-94.551', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (935, N'Atlanta', N' Georgia', N'33.7629', N'-84.4227', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (936, N'Long Beach', N' California', N'33.8092', N'-118.1553', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (937, N'Omaha', N' Nebraska', N'41.2644', N'-96.0451', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (938, N'Raleigh', N' North Carolina', N'35.8306', N'-78.6418', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (939, N'Colorado Springs', N' Colorado', N'38.8673', N'-104.7607', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (940, N'Miami', N' Florida', N'25.7752', N'-80.2086', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (941, N'Virginia Beach', N' Virginia', N'36.78', N'-76.0252', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (942, N'Oakland', N' California', N'37.7698', N'-122.2257', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (943, N'Minneapolis', N' Minnesota', N'44.9633', N'-93.2683', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (944, N'Tulsa', N' Oklahoma', N'36.1279', N'-95.9023', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (945, N'Arlington', N' Texas', N'32.7007', N'-97.1247', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (946, N'New Orleans', N' Louisiana', N'30.0534', N'-89.9345', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (947, N'Wichita', N' Kansas', N'37.6907', N'-97.3459', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (948, N'Cleveland', N' Ohio', N'41.4785', N'-81.6794', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (949, N'Tampa', N' Florida', N'27.9701', N'-82.4797', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (950, N'Bakersfield', N' California', N'35.3212', N'-119.0183', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (951, N'Aurora', N' Colorado', N'39.688', N'-104.6897', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (952, N'Anaheim', N' California', N'33.8555', N'-117.7601', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (953, N'Honolulu', N' Hawaii', N'21.3243', N'-157.8476', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (954, N'Santa Ana', N' California', N'33.7363', N'-117.883', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (955, N'Riverside', N' California', N'33.9381', N'-117.3932', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (956, N'Corpus Christi', N' Texas', N'27.7543', N'-97.1734', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (957, N'Lexington', N' Kentucky', N'38.0407', N'-84.4583', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (958, N'Stockton', N' California', N'37.9763', N'-121.3133', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (959, N'St. Louis', N' Missouri', N'38.6357', N'-90.2446', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (960, N'Saint Paul', N' Minnesota', N'44.9489', N'-93.1041', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (961, N'Henderson', N' Nevada', N'36.0097', N'-115.0357', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (962, N'Pittsburgh', N' Pennsylvania', N'40.4398', N'-79.9766', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (963, N'Cincinnati', N' Ohio', N'39.1402', N'-84.5058', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (964, N'Anchorage', N' Alaska', N'61.1743', N'-149.2843', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (965, N'Greensboro', N' North Carolina', N'36.0951', N'-79.827', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (966, N'Plano', N' Texas', N'33.0508', N'-96.7479', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (967, N'Newark', N' New Jersey', N'40.7242', N'-74.1726', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (968, N'Lincoln', N' Nebraska', N'40.8105', N'-96.6803', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (969, N'Orlando', N' Florida', N'28.4166', N'-81.2736', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (970, N'Irvine', N' California', N'33.6784', N'-117.7713', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (971, N'Toledo', N' Ohio', N'41.6641', N'-83.5819', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (972, N'Jersey', N' New Jersey', N'40.7114', N'-74.0648', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (973, N'Chula Vista', N' California', N'32.6277', N'-117.0152', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (974, N'Durham', N' North Carolina', N'35.9811', N'-78.9029', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (975, N'Fort Wayne', N' Indiana', N'41.0882', N'-85.1439', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (976, N'St. Petersburg', N' Florida', N'27.762', N'-82.6441', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (977, N'Laredo', N' Texas', N'27.5604', N'-99.4892', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (978, N'Buffalo', N' New York', N'42.8925', N'-78.8597', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (979, N'Madison', N' Wisconsin', N'43.0878', N'-89.4299', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (980, N'Lubbock', N' Texas', N'33.5656', N'-101.8867', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (981, N'Chandler', N' Arizona', N'33.2829', N'-111.8549', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (982, N'Scottsdale', N' Arizona', N'33.6843', N'-111.8611', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (983, N'Reno', N' Nevada', N'39.5491', N'-119.8499', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (984, N'Glendale', N' Arizona', N'33.5331', N'-112.1899', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (985, N'Norfolk', N' Virginia', N'36.923', N'-76.2446', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (986, N'Winston–Salem', N' North Carolina', N'36.1027', N'-80.261', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (987, N'North Las Vegas', N' Nevada', N'36.2857', N'-115.0939', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (988, N'Gilbert', N' Arizona', N'33.3103', N'-111.7431', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (989, N'Chesapeake', N' Virginia', N'36.6794', N'-76.3018', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (990, N'Irving', N' Texas', N'32.8577', N'-96.97', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (991, N'Hialeah', N' Florida', N'25.8699', N'-80.3029', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (992, N'Garland', N' Texas', N'32.9098', N'-96.6303', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (993, N'Fremont', N' California', N'37.4945', N'-121.9412', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (994, N'Richmond', N' Virginia', N'37.5314', N'-77.476', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (995, N'Boise', N' Idaho', N'43.6002', N'-116.2317', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (996, N'Baton Rouge', N' Louisiana', N'30.4422', N'-91.1309', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (997, N'Des Moines', N' Iowa', N'41.5726', N'-93.6102', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (998, N'Spokane', N' Washington', N'47.6669', N'-117.4333', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (999, N'San Bernardino', N' California', N'34.1416', N'-117.2936', N'United States')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1000, N'Modesto', N' California', N'37.6375', N'-121.003', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1001, N'Tacoma', N' Washington', N'47.2522', N'-122.4598', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1002, N'Fontana', N' California', N'34.109', N'-117.4629', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1003, N'Santa Clarita', N' California', N'34.403', N'-118.5042', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1004, N'Birmingham', N' Alabama', N'33.5274', N'-86.799', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1005, N'Oxnard', N' California', N'34.2023', N'-119.2046', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1006, N'Fayetteville', N' North Carolina', N'35.0828', N'-78.9735', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1007, N'Rochester', N' New York', N'43.1699', N'-77.6169', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1008, N'Moreno Valley', N' California', N'33.9233', N'-117.2057', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1009, N'Glendale', N' California', N'34.1814', N'-118.2458', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1010, N'Yonkers', N' New York', N'40.9459', N'-73.8674', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1011, N'Huntington Beach', N' California', N'33.6906', N'-118.0093', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1012, N'Aurora', N' Illinois', N'41.7635', N'-88.2901', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1013, N'Salt Lake', N' Utah', N'40.7769', N'-111.931', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1014, N'Amarillo', N' Texas', N'35.1999', N'-101.8302', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1015, N'Montgomery', N' Alabama', N'32.3472', N'-86.2661', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1016, N'Grand Rapids', N' Michigan', N'42.9612', N'-85.6556', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1017, N'Little Rock', N' Arkansas', N'34.7254', N'-92.3586', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1018, N'Akron', N' Ohio', N'41.0805', N'-81.5214', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1019, N'Augusta', N' Georgia', N'33.3655', N'-82.0734', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1020, N'Huntsville', N' Alabama', N'34.699', N'-86.673', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1021, N'Columbus', N' Georgia', N'32.5102', N'-84.8749', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1022, N'Grand Prairie', N' Texas', N'32.6869', N'-97.0211', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1023, N'Shreveport', N' Louisiana', N'32.4669', N'-93.7922', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1024, N'Overland Park', N' Kansas', N'38.889', N'-94.6906', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1025, N'Tallahassee', N' Florida', N'30.4551', N'-84.2534', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1026, N'Mobile', N' Alabama', N'30.6684', N'-88.1002', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1027, N'Port St. Lucie', N' Florida', N'27.2806', N'-80.3883', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1028, N'Knoxville', N' Tennessee', N'35.9707', N'-83.9493', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1029, N'Worcester', N' Massachusetts', N'42.2695', N'-71.8078', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1030, N'Tempe', N' Arizona', N'33.3884', N'-111.9318', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1031, N'Cape Coral', N' Florida', N'26.6432', N'-81.9974', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1032, N'Brownsville', N' Texas', N'25.9991', N'-97.455', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1033, N'McKinney', N' Texas', N'33.1985', N'-96.668', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1034, N'Providence', N' Rhode Island', N'41.8231', N'-71.4188', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1035, N'Fort Lauderdale', N' Florida', N'26.1412', N'-80.1467', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1036, N'Newport News', N' Virginia', N'37.0762', N'-76.522', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1037, N'Chattanooga', N' Tennessee', N'35.066', N'-85.2484', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1038, N'Rancho Cucamonga', N' California', N'34.1233', N'-117.5642', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1039, N'Frisco', N' Texas', N'33.1554', N'-96.8226', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1040, N'Sioux Falls', N' South Dakota', N'43.5383', N'-96.732', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1041, N'Oceanside', N' California', N'33.2245', N'-117.3062', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1042, N'Ontario', N' California', N'34.0394', N'-117.6042', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1043, N'Vancouver', N' Washington', N'45.6349', N'-122.5957', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1044, N'Santa Rosa', N' California', N'38.4468', N'-122.7061', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1045, N'Garden Grove', N' California', N'33.7788', N'-117.9605', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1046, N'Elk Grove', N' California', N'38.4146', N'-121.385', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1047, N'Pembroke Pines', N' Florida', N'26.021', N'-80.3404', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1048, N'Salem', N' Oregon', N'44.9237', N'-123.0232', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1049, N'Eugene', N' Oregon', N'44.0567', N'-123.1162', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1050, N'Peoria', N' Arizona', N'33.7862', N'-112.308', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1051, N'Corona', N' California', N'33.862', N'-117.5655', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1052, N'Springfield', N' Missouri', N'37.1942', N'-93.2913', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1053, N'Jackson', N' Mississippi', N'32.3158', N'-90.2128', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1054, N'Cary', N' North Carolina', N'35.7809', N'-78.8133', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1055, N'Fort Collins', N' Colorado', N'40.5482', N'-105.0648', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1056, N'Hayward', N' California', N'37.6287', N'-122.1024', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1057, N'Lancaster', N' California', N'34.6936', N'-118.1753', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1058, N'Alexandria', N' Virginia', N'38.8201', N'-77.0841', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1059, N'Salinas', N' California', N'36.6902', N'-121.6337', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1060, N'Palmdale', N' California', N'34.591', N'-118.1054', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1061, N'Lakewood', N' Colorado', N'39.6989', N'-105.1176', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1062, N'Springfield', N' Massachusetts', N'42.1155', N'-72.54', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1063, N'Sunnyvale', N' California', N'37.3858', N'-122.0263', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1064, N'Hollywood', N' Florida', N'26.031', N'-80.1646', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1065, N'Pasadena', N' Texas', N'29.6586', N'-95.1506', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1066, N'Clarksville', N' Tennessee', N'36.5664', N'-87.3452', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1067, N'Pomona', N' California', N'34.0585', N'-117.7611', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1068, N'Kansas', N' Kansas', N'39.1225', N'-94.7418', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1069, N'Macon', N' Georgia', N'32.8088', N'-83.6942', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1070, N'Escondido', N' California', N'33.1331', N'-117.074', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1071, N'Paterson', N' New Jersey', N'40.9148', N'-74.1628', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1072, N'Joliet', N' Illinois', N'41.5177', N'-88.1488', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1073, N'Naperville', N' Illinois', N'41.7492', N'-88.162', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1074, N'Rockford', N' Illinois', N'42.2588', N'-89.0646', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1075, N'Torrance', N' California', N'33.835', N'-118.3414', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1076, N'Bridgeport', N' Connecticut', N'41.1874', N'-73.1958', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1077, N'Savannah', N' Georgia', N'32.0025', N'-81.1536', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1078, N'Killeen', N' Texas', N'31.0777', N'-97.732', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1079, N'Bellevue', N' Washington', N'47.5979', N'-122.1565', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1080, N'Mesquite', N' Texas', N'32.7629', N'-96.5888', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1081, N'Syracuse', N' New York', N'43.041', N'-76.1436', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1082, N'McAllen', N' Texas', N'26.2322', N'-98.2464', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1083, N'Pasadena', N' California', N'34.1606', N'-118.1396', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1084, N'Orange', N' California', N'33.787', N'-117.8613', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1085, N'Fullerton', N' California', N'33.8857', N'-117.928', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1086, N'Dayton', N' Ohio', N'39.7774', N'-84.1996', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1087, N'Miramar', N' Florida', N'25.977', N'-80.3358', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1088, N'Olathe', N' Kansas', N'38.8843', N'-94.8195', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1089, N'Thornton', N' Colorado', N'39.9194', N'-104.9428', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1090, N'Waco', N' Texas', N'31.5601', N'-97.186', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1091, N'Murfreesboro', N' Tennessee', N'35.8522', N'-86.416', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1092, N'Denton', N' Texas', N'33.2166', N'-97.1414', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1093, N'West Valley', N' Utah', N'40.6885', N'-112.0118', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1094, N'Midland', N' Texas', N'32.0246', N'-102.1135', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1095, N'Carrollton', N' Texas', N'32.9884', N'-96.8998', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1096, N'Roseville', N' California', N'38.769', N'-121.3189', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1097, N'Warren', N' Michigan', N'42.4929', N'-83.025', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1098, N'Charleston', N' South Carolina', N'32.8179', N'-79.959', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1099, N'Hampton', N' Virginia', N'37.048', N'-76.2971', N'United States')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1100, N'Surprise', N' Arizona', N'33.6706', N'-112.4527', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1101, N'Columbia', N' South Carolina', N'34.0291', N'-80.898', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1102, N'Coral Springs', N' Florida', N'26.2707', N'-80.2593', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1103, N'Visalia', N' California', N'36.3273', N'-119.3289', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1104, N'Sterling Heights', N' Michigan', N'42.5812', N'-83.0303', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1105, N'Gainesville', N' Florida', N'29.6788', N'-82.3461', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1106, N'Cedar Rapids', N' Iowa', N'41.967', N'-91.6778', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1107, N'New Haven', N' Connecticut', N'41.3108', N'-72.925', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1108, N'Stamford', N' Connecticut', N'41.0799', N'-73.546', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1109, N'Elizabeth', N' New Jersey', N'40.6664', N'-74.1935', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1110, N'Concord', N' California', N'37.9722', N'-122.0016', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1111, N'Thousand Oaks', N' California', N'34.1933', N'-118.8742', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1112, N'Kent', N' Washington', N'47.388', N'-122.2127', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1113, N'Santa Clara', N' California', N'37.3646', N'-121.9679', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1114, N'Simi Valley', N' California', N'34.2669', N'-118.7485', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1115, N'Lafayette', N' Louisiana', N'30.2074', N'-92.0285', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1116, N'Topeka', N' Kansas', N'39.0347', N'-95.6962', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1117, N'Athens', N' Georgia', N'33.9496', N'-83.3701', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1118, N'Round Rock', N' Texas', N'30.5252', N'-97.666', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1119, N'Hartford', N' Connecticut', N'41.7659', N'-72.6816', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1120, N'Norman', N' Oklahoma', N'35.2406', N'-97.3453', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1121, N'Victorville', N' California', N'34.5277', N'-117.3536', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1122, N'Fargo', N'  North Dakota', N'46.8652', N'-96.829', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1123, N'Berkeley', N' California', N'37.867', N'-122.2991', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1124, N'Vallejo', N' California', N'38.1079', N'-122.264', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1125, N'Abilene', N' Texas', N'32.4545', N'-99.7381', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1126, N'Columbia', N' Missouri', N'38.951561', N'-92.328638', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1127, N'Ann Arbor', N' Michigan', N'42.2761', N'-83.7309', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1128, N'Allentown', N' Pennsylvania', N'40.5936', N'-75.4784', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1129, N'Pearland', N' Texas', N'29.5558', N'-95.3231', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1130, N'Beaumont', N' Texas', N'30.0849', N'-94.1453', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1131, N'Wilmington', N' North Carolina', N'34.2092', N'-77.8858', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1132, N'Evansville', N' Indiana', N'37.9877', N'-87.5347', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1133, N'Arvada', N' Colorado', N'39.8337', N'-105.1503', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1134, N'Provo', N' Utah', N'40.2453', N'-111.6448', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1135, N'Independence', N' Missouri', N'39.0855', N'-94.3521', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1136, N'Lansing', N' Michigan', N'42.7143', N'-84.5593', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1137, N'Odessa', N' Texas', N'31.8838', N'-102.3411', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1138, N'Richardson', N' Texas', N'32.9723', N'-96.7081', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1139, N'Fairfield', N' California', N'38.2593', N'-122.0321', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1140, N'El Monte', N' California', N'34.0746', N'-118.0291', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1141, N'Rochester', N' Minnesota', N'44.0154', N'-92.4772', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1142, N'Clearwater', N' Florida', N'27.9789', N'-82.7666', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1143, N'Carlsbad', N' California', N'33.1239', N'-117.2828', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1144, N'Springfield', N' Illinois', N'39.7911', N'-89.6446', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1145, N'Temecula', N' California', N'33.4931', N'-117.1317', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1146, N'West Jordan', N' Utah', N'40.6024', N'-112.0008', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1147, N'Costa Mesa', N' California', N'33.6659', N'-117.9123', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1148, N'Miami Gardens', N' Florida', N'25.9489', N'-80.2436', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1149, N'Cambridge', N' Massachusetts', N'42.376', N'-71.1187', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1150, N'College Station', N' Texas', N'30.5852', N'-96.2964', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1151, N'Murrieta', N' California', N'33.5721', N'-117.1904', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1152, N'Downey', N' California', N'33.9382', N'-118.1309', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1153, N'Peoria', N' Illinois', N'40.7515', N'-89.6174', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1154, N'Westminster', N' Colorado', N'39.8822', N'-105.0644', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1155, N'Elgin', N' Illinois', N'42.0396', N'-88.3217', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1156, N'Antioch', N' California', N'37.9791', N'-121.7962', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1157, N'Palm Bay', N' Florida', N'27.9856', N'-80.6626', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1158, N'High Point', N' North Carolina', N'35.99', N'-79.9905', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1159, N'Lowell', N' Massachusetts', N'42.639', N'-71.3211', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1160, N'Manchester', N' New Hampshire', N'42.9849', N'-71.4441', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1161, N'Pueblo', N' Colorado', N'38.2699', N'-104.6123', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1162, N'Gresham', N' Oregon', N'45.5023', N'-122.4416', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1163, N'North Charleston', N' South Carolina', N'32.9178', N'-80.065', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1164, N'Ventura', N' California', N'34.2678', N'-119.2542', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1165, N'Inglewood', N' California', N'33.9561', N'-118.3443', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1166, N'Pompano Beach', N' Florida', N'26.2416', N'-80.1339', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1167, N'Centennial', N' Colorado', N'39.5906', N'-104.8691', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1168, N'West Palm Beach', N' Florida', N'26.7464', N'-80.1251', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1169, N'Everett', N' Washington', N'47.9566', N'-122.1914', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1170, N'Richmond', N' California', N'37.9523', N'-122.3606', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1171, N'Clovis', N' California', N'36.8282', N'-119.6849', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1172, N'Billings', N' Montana', N'45.7885', N'-108.5499', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1173, N'Waterbury', N' Connecticut', N'41.5585', N'-73.0367', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1174, N'Broken Arrow', N' Oklahoma', N'36.0365', N'-95.781', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1175, N'Lakeland', N' Florida', N'28.0555', N'-81.9549', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1176, N'West Covina', N' California', N'34.0559', N'-117.9099', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1177, N'Boulder', N' Colorado', N'40.027', N'-105.2519', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1178, N'Daly City', N' California', N'37.7009', N'-122.465', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1179, N'Santa Maria', N' California', N'34.9332', N'-120.4438', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1180, N'Hillsboro', N' Oregon', N'45.528', N'-122.9357', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1181, N'Sandy Springs', N' Georgia', N'33.9315', N'-84.3687', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1182, N'Norwalk', N' California', N'33.9076', N'-118.0835', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1183, N'Jurupa Valley', N' California', N'34.0026', N'-117.4676', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1184, N'Lewisville', N' Texas', N'33.0466', N'-96.9818', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1185, N'Greeley', N' Colorado', N'40.4153', N'-104.7697', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1186, N'Davie', N' Florida', N'26.0791', N'-80.285', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1187, N'Green Bay', N' Wisconsin', N'44.5207', N'-87.9842', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1188, N'Tyler', N' Texas', N'32.3173', N'-95.3059', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1189, N'League City', N' Texas', N'29.4901', N'-95.1091', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1190, N'Burbank', N' California', N'34.1901', N'-118.3264', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1191, N'San Mateo', N' California', N'37.5603', N'-122.3106', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1192, N'Wichita Falls', N' Texas', N'33.9067', N'-98.5259', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1193, N'El Cajon', N' California', N'32.8017', N'-116.9604', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1194, N'Rialto', N' California', N'34.1118', N'-117.3883', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1195, N'Lakewood', N' New Jersey', N'40.0771', N'-74.2004', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1196, N'Edison', N' New Jersey', N'40.504', N'-74.3494', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1197, N'Davenport', N' Iowa', N'41.5541', N'-90.604', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1198, N'South Bend', N' Indiana', N'41.6769', N'-86.269', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1199, N'Woodbridge', N' New Jersey', N'40.5607', N'-74.2927', N'United States')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1200, N'Las Cruces', N' New Mexico', N'32.3264', N'-106.7897', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1201, N'Vista', N' California', N'33.1895', N'-117.2386', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1202, N'Renton', N' Washington', N'47.4761', N'-122.192', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1203, N'Sparks', N' Nevada', N'39.5544', N'-119.7356', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1204, N'Clinton', N' Michigan', N'42.5903', N'-82.917', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1205, N'Allen', N' Texas', N'33.0997', N'-96.6631', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1206, N'Tuscaloosa', N' Alabama', N'33.2065', N'-87.5346', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1207, N'San Angelo', N' Texas', N'31.4411', N'-100.4505', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1208, N'Vacaville', N' California', N'38.3539', N'-121.9728', N'United States')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1209, N'Karachi', N'Sindh', N'24.9056', N'67.0822', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1210, N'Lahore', N'Punjab', N'31.549722', N'74.343611', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1211, N'Faisalabad', N'Punjab', N'31.416667', N'73.083333', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1212, N'Serai', N'Khyber Pakhtunkhwa', N'34.73933', N'72.335655', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1213, N'Rawalpindi', N'Punjab', N'33.597331', N'73.047904', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1214, N'Multan', N'Punjab', N'30.196789', N'71.478241', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1215, N'Gujranwala', N'Punjab', N'32.155667', N'74.187052', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1216, N'Hyderabad City', N'Sindh', N'25.396891', N'68.377183', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1217, N'Peshawar', N'Khyber Pakhtunkhwa', N'34.008', N'71.578488', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1218, N'Abbottabad', N'Khyber Pakhtunkhwa', N'34.1463', N'73.211684', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1219, N'Islamabad', N'Islamabad', N'33.69', N'73.0551', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1220, N'Quetta', N'Balochistan', N'30.184138', N'67.00141', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1221, N'Bannu', N'Khyber Pakhtunkhwa', N'32.985414', N'70.602701', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1222, N'Bahawalpur', N'Punjab', N'29.4', N'71.683333', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1223, N'Sargodha', N'Punjab', N'32.083611', N'72.671111', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1224, N'Sialkot City', N'Punjab', N'32.499101', N'74.52502', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1225, N'Sukkur', N'Sindh', N'27.705164', N'68.857383', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1226, N'Larkana', N'Sindh', N'27.558985', N'68.212035', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1227, N'Sheikhupura', N'Punjab', N'31.713056', N'73.978333', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1228, N'Mirpur Khas', N'Sindh', N'25.5251', N'69.0159', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1229, N'Rahimyar Khan', N'Punjab', N'28.419482', N'70.302386', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1230, N'Kohat', N'Khyber Pakhtunkhwa', N'33.581958', N'71.449291', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1231, N'Jhang Sadr', N'Punjab', N'31.269811', N'72.316867', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1232, N'Gujrat', N'Punjab', N'32.574204', N'74.075423', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1233, N'Bardar', N'Khyber Pakhtunkhwa', N'34.163737', N'72.011571', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1234, N'Kasur', N'Punjab', N'31.115556', N'74.446667', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1235, N'Dera Ghazi Khan', N'Punjab', N'30.056142', N'70.634766', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1236, N'Masiwala', N'Punjab', N'30.683333', N'73.066667', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1237, N'Nawabshah', N'Sindh', N'26.248334', N'68.409554', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1238, N'Okara', N'Punjab', N'30.808056', N'73.445833', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1239, N'Gilgit', N'Gilgit-Baltistan', N'35.920007', N'74.313656', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1240, N'Chiniot', N'Punjab', N'31.72', N'72.978889', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1241, N'Sadiqabad', N'Punjab', N'28.30623', N'70.130646', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1242, N'Turbat', N'Balochistan', N'26.001224', N'63.048491', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1243, N'Dera Ismail Khan', N'Khyber Pakhtunkhwa', N'31.832691', N'70.902398', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1244, N'Chaman', N'Balochistan', N'30.917689', N'66.45259', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1245, N'Zhob', N'Balochistan', N'31.340817', N'69.449304', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1246, N'Mehra', N'Khyber Pakhtunkhwa', N'34.312817', N'73.220525', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1247, N'Parachinar', N'Federally Administered Tribal Areas', N'33.895672', N'70.098875', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1248, N'Gwadar', N'Balochistan', N'25.12163', N'62.325411', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1249, N'Kundian', N'Punjab', N'32.457747', N'71.478918', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1250, N'Shahdad Kot', N'Sindh', N'27.847263', N'67.906789', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1251, N'Haripur', N'Khyber Pakhtunkhwa', N'33.999967', N'72.934093', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1252, N'Matiari', N'Sindh', N'25.59709', N'68.4467', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1253, N'Dera Allahyar', N'Balochistan', N'28.373529', N'68.350778', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1254, N'Lodhran', N'Punjab', N'29.540507', N'71.63357', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1255, N'Batgram', N'Khyber Pakhtunkhwa', N'34.679637', N'73.026299', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1256, N'Thatta', N'Sindh', N'24.747449', N'67.923528', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1257, N'Bagh', N'Azad Kashmir', N'33.981106', N'73.776084', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1258, N'Badin', N'Sindh', N'24.655995', N'68.836997', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1259, N'Mansehra', N'Khyber Pakhtunkhwa', N'34.330232', N'73.196788', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1260, N'Ziarat', N'Balochistan', N'30.382444', N'67.725624', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1261, N'Muzaffargarh', N'Punjab', N'30.072576', N'71.193788', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1262, N'Tando Allahyar', N'Sindh', N'25.462626', N'68.719233', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1263, N'Dera Murad Jamali', N'Balochistan', N'28.546568', N'68.223081', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1264, N'Karak', N'Khyber Pakhtunkhwa', N'33.116334', N'71.093536', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1265, N'Mardan', N'Khyber Pakhtunkhwa', N'34.197943', N'72.04965', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1266, N'Uthal', N'Balochistan', N'25.807222', N'66.621944', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1267, N'Nankana Sahib', N'Punjab', N'31.4475', N'73.697222', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1268, N'Barkhan', N'Balochistan', N'29.897727', N'69.525584', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1269, N'Hafizabad', N'Punjab', N'32.067857', N'73.685449', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1270, N'Kotli', N'Azad Kashmir', N'33.518362', N'73.902203', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1271, N'Loralai', N'Balochistan', N'30.370512', N'68.597949', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1272, N'Dera Bugti', N'Balochistan', N'29.036188', N'69.158493', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1273, N'Jhang City', N'Punjab', N'31.305684', N'72.325941', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1274, N'Sahiwal', N'Punjab', N'30.666667', N'73.1', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1275, N'Sanghar', N'Sindh', N'26.046558', N'68.9481', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1276, N'Pakpattan', N'Punjab', N'30.341044', N'73.386642', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1277, N'Chakwal', N'Punjab', N'32.933376', N'72.858531', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1278, N'Khushab', N'Punjab', N'32.296667', N'72.3525', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1279, N'Ghotki', N'Sindh', N'28.00604', N'69.316077', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1280, N'Kohlu', N'Balochistan', N'29.896505', N'69.253235', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1281, N'Khuzdar', N'Balochistan', N'27.738385', N'66.643365', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1282, N'Awaran', N'Balochistan', N'26.456768', N'65.231436', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1283, N'Nowshera', N'Khyber Pakhtunkhwa', N'34.015828', N'71.981232', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1284, N'Charsadda', N'Khyber Pakhtunkhwa', N'34.148221', N'71.740604', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1285, N'Qila Abdullah', N'Balochistan', N'30.728035', N'66.661174', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1286, N'Bahawalnagar', N'Punjab', N'29.998659', N'73.253604', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1287, N'Dadu', N'Sindh', N'26.730334', N'67.776896', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1288, N'Aliabad', N'Gilgit-Baltistan', N'36.307028', N'74.615449', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1289, N'Lakki Marwat', N'Khyber Pakhtunkhwa', N'32.607953', N'70.911416', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1290, N'Chilas', N'Gilgit-Baltistan', N'35.412867', N'74.104068', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1291, N'Pishin', N'Balochistan', N'30.581762', N'66.994061', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1292, N'Tank', N'Khyber Pakhtunkhwa', N'32.217071', N'70.383154', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1293, N'Chitral', N'Khyber Pakhtunkhwa', N'35.851802', N'71.786358', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1294, N'Qila Saifullah', N'Balochistan', N'30.700766', N'68.359843', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1295, N'Shikarpur', N'Sindh', N'27.957057', N'68.637886', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1296, N'Panjgur', N'Balochistan', N'26.971861', N'64.094594', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1297, N'Mastung', N'Balochistan', N'29.799656', N'66.845527', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1298, N'Kalat', N'Balochistan', N'29.026629', N'66.593607', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1299, N'Gandava', N'Balochistan', N'28.613207', N'67.485643', N'Pakistan')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1300, N'Khanewal', N'Punjab', N'30.301731', N'71.932124', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1301, N'Narowal', N'Punjab', N'32.1', N'74.883333', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1302, N'Khairpur', N'Sindh', N'27.529483', N'68.761698', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1303, N'Malakand', N'Khyber Pakhtunkhwa', N'34.565609', N'71.930432', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1304, N'Vihari', N'Punjab', N'30.033333', N'72.35', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1305, N'Saidu Sharif', N'Khyber Pakhtunkhwa', N'34.746548', N'72.355675', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1306, N'Jhelum', N'Punjab', N'32.934484', N'73.731018', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1307, N'Mandi Bahauddin', N'Punjab', N'32.587037', N'73.491231', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1308, N'Bhakkar', N'Punjab', N'31.625247', N'71.06574', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1309, N'Toba Tek Singh', N'Punjab', N'30.974326', N'72.482694', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1310, N'Jamshoro', N'Sindh', N'25.436078', N'68.280172', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1311, N'Kharan', N'Balochistan', N'28.584585', N'65.415007', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1312, N'Umarkot', N'Sindh', N'25.36157', N'69.736241', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1313, N'Hangu', N'Khyber Pakhtunkhwa', N'33.53198', N'71.059499', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1314, N'Timargara', N'Khyber Pakhtunkhwa', N'34.826595', N'71.844226', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1315, N'Gakuch', N'Gilgit-Baltistan', N'36.176826', N'73.763834', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1316, N'Jacobabad', N'Sindh', N'28.281873', N'68.437613', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1317, N'Alpurai', N'Khyber Pakhtunkhwa', N'34.920577', N'72.632556', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1318, N'Mianwali', N'Punjab', N'32.574095', N'71.526386', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1319, N'Musa Khel Bazar', N'Balochistan', N'30.859443', N'69.82208', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1320, N'Naushahro Firoz', N'Sindh', N'26.840104', N'68.122651', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1321, N'New Mirpur', N'Azad Kashmir', N'33.147815', N'73.751867', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1322, N'Daggar', N'Khyber Pakhtunkhwa', N'34.511059', N'72.484375', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1323, N'Eidgah', N'Gilgit-Baltistan', N'35.347115', N'74.856317', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1324, N'Sibi', N'Balochistan', N'29.542989', N'67.87726', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1325, N'Dalbandin', N'Balochistan', N'28.888456', N'64.406156', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1326, N'Rajanpur', N'Punjab', N'29.103513', N'70.325038', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1327, N'Leiah', N'Punjab', N'30.961279', N'70.939043', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1328, N'Upper Dir', N'Khyber Pakhtunkhwa', N'35.207398', N'71.876801', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1329, N'Tando Muhammad Khan', N'Sindh', N'25.123007', N'68.535773', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1330, N'Attock City', N'Punjab', N'33.76671', N'72.359766', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1331, N'Rawala Kot', N'Azad Kashmir', N'33.857816', N'73.760426', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1332, N'Swabi', N'Khyber Pakhtunkhwa', N'34.120181', N'72.46982', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1333, N'Kandhkot', N'Sindh', N'28.243963', N'69.182354', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1334, N'Dasu', N'Khyber Pakhtunkhwa', N'35.291687', N'73.290602', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1335, N'Athmuqam', N'Azad Kashmir', N'34.571733', N'73.897236', N'Pakistan')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1336, N'Toronto', N'Ontario', N'43.666667', N'-79.416667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1337, N'Montréal', N'Québec', N'45.5', N'-73.583333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1338, N'Vancouver', N'British Columbia', N'49.25', N'-123.133333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1339, N'Ottawa', N'Ontario', N'45.416667', N'-75.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1340, N'Calgary', N'Alberta', N'51.083333', N'-114.083333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1341, N'Edmonton', N'Alberta', N'53.55', N'-113.5', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1342, N'Hamilton', N'Ontario', N'43.256101', N'-79.857484', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1343, N'Winnipeg', N'Manitoba', N'49.883333', N'-97.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1344, N'Québec', N'Québec', N'46.8', N'-71.25', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1345, N'Oshawa', N'Ontario', N'43.9', N'-78.866667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1346, N'Kitchener', N'Ontario', N'43.446976', N'-80.472484', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1347, N'Halifax', N'Nova Scotia', N'44.65', N'-63.6', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1348, N'London', N'Ontario', N'42.983333', N'-81.25', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1349, N'Windsor', N'Ontario', N'42.301649', N'-83.030744', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1350, N'Victoria', N'British Columbia', N'48.450234', N'-123.343529', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1351, N'Saskatoon', N'Saskatchewan', N'52.133333', N'-106.666667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1352, N'Barrie', N'Ontario', N'44.383333', N'-79.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1353, N'Regina', N'Saskatchewan', N'50.45', N'-104.616667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1354, N'Sudbury', N'Ontario', N'46.5', N'-80.966667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1355, N'Abbotsford', N'British Columbia', N'49.05', N'-122.3', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1356, N'Sarnia', N'Ontario', N'42.978417', N'-82.388177', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1357, N'Sherbrooke', N'Québec', N'45.4', N'-71.9', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1358, N'Saint John’s', N'Newfoundland and Labrador', N'47.55', N'-52.666667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1359, N'Kelowna', N'British Columbia', N'49.9', N'-119.483333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1360, N'Trois-Rivières', N'Québec', N'46.35', N'-72.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1361, N'Kingston', N'Ontario', N'44.3', N'-76.566667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1362, N'Thunder Bay', N'Ontario', N'48.4', N'-89.233333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1363, N'Moncton', N'New Brunswick', N'46.09652', N'-64.79757', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1364, N'Saint John', N'New Brunswick', N'45.230798', N'-66.095316', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1365, N'Nanaimo', N'British Columbia', N'49.15', N'-123.916667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1366, N'Peterborough', N'Ontario', N'44.3', N'-78.333333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1367, N'Saint-Jérôme', N'Québec', N'45.766667', N'-74', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1368, N'Red Deer', N'Alberta', N'52.266667', N'-113.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1369, N'Lethbridge', N'Alberta', N'49.7', N'-112.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1370, N'Kamloops', N'British Columbia', N'50.666667', N'-120.333333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1371, N'Prince George', N'British Columbia', N'53.916667', N'-122.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1372, N'Medicine Hat', N'Alberta', N'50.033333', N'-110.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1373, N'Drummondville', N'Québec', N'45.883333', N'-72.483333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1374, N'Chicoutimi', N'Québec', N'48.45', N'-71.066667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1375, N'Fredericton', N'New Brunswick', N'45.910648', N'-66.658649', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1376, N'Chilliwack', N'British Columbia', N'49.166667', N'-121.95', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1377, N'North Bay', N'Ontario', N'46.3', N'-79.45', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1378, N'Shawinigan-Sud', N'Québec', N'46.528557', N'-72.751453', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1379, N'Cornwall', N'Ontario', N'45.016667', N'-74.733333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1380, N'Joliette', N'Québec', N'46.034', N'-73.441', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1381, N'Belleville', N'Ontario', N'44.166667', N'-77.383333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1382, N'Charlottetown', N'Prince Edward Island', N'46.238225', N'-63.139481', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1383, N'Victoriaville', N'Québec', N'46.063106', N'-71.958802', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1384, N'Grande Prairie', N'Alberta', N'55.166667', N'-118.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1385, N'Penticton', N'British Columbia', N'49.5', N'-119.583333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1386, N'Sydney', N'Nova Scotia', N'46.15', N'-60.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1387, N'Orillia', N'Ontario', N'44.6', N'-79.416667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1388, N'Rimouski', N'Québec', N'48.433333', N'-68.516667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1389, N'Timmins', N'Ontario', N'48.466667', N'-81.333333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1390, N'Prince Albert', N'Saskatchewan', N'53.2', N'-105.75', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1391, N'Campbell River', N'British Columbia', N'50.016667', N'-125.25', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1392, N'Courtenay', N'British Columbia', N'49.683333', N'-125', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1393, N'Orangeville', N'Ontario', N'43.916366', N'-80.096671', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1394, N'Moose Jaw', N'Saskatchewan', N'50.4', N'-105.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1395, N'Brandon', N'Manitoba', N'49.833333', N'-99.95', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1396, N'Brockville', N'Ontario', N'44.594958', N'-75.682133', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1397, N'Saint-Georges', N'Québec', N'46.116667', N'-70.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1398, N'Sept-Îles', N'Québec', N'50.2', N'-66.383333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1399, N'Rouyn-Noranda', N'Québec', N'48.25', N'-79.016667', N'Canada')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1400, N'Whitehorse', N'Yukon', N'60.716667', N'-135.05', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1401, N'Owen Sound', N'Ontario', N'44.566667', N'-80.85', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1402, N'Fort McMurray', N'Alberta', N'56.733333', N'-111.383333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1403, N'Corner Brook', N'Newfoundland and Labrador', N'48.95', N'-57.933333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1404, N'Val-d’Or', N'Québec', N'48.116667', N'-77.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1405, N'New Glasgow', N'Nova Scotia', N'45.583333', N'-62.633333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1406, N'Terrace', N'British Columbia', N'54.5', N'-128.583333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1407, N'North Battleford', N'Saskatchewan', N'52.766667', N'-108.283333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1408, N'Yellowknife', N'Northwest Territories', N'62.45', N'-114.35', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1409, N'Fort Saint John', N'British Columbia', N'56.25', N'-120.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1410, N'Cranbrook', N'British Columbia', N'49.516667', N'-115.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1411, N'Edmundston', N'New Brunswick', N'47.36226', N'-68.327874', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1412, N'Rivière-du-Loup', N'Québec', N'47.833333', N'-69.533333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1413, N'Camrose', N'Alberta', N'53.016667', N'-112.816667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1414, N'Pembroke', N'Ontario', N'45.816667', N'-77.116667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1415, N'Yorkton', N'Saskatchewan', N'51.216667', N'-102.466667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1416, N'Swift Current', N'Saskatchewan', N'50.283333', N'-107.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1417, N'Prince Rupert', N'British Columbia', N'54.316667', N'-130.333333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1418, N'Williams Lake', N'British Columbia', N'52.116667', N'-122.15', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1419, N'Brooks', N'Alberta', N'50.566667', N'-111.9', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1420, N'Quesnel', N'British Columbia', N'52.983333', N'-122.483333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1421, N'Thompson', N'Manitoba', N'55.75', N'-97.866667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1422, N'Dolbeau', N'Québec', N'48.866667', N'-72.233333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1423, N'Powell River', N'British Columbia', N'49.883333', N'-124.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1424, N'Wetaskiwin', N'Alberta', N'52.966667', N'-113.383333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1425, N'Nelson', N'British Columbia', N'49.483333', N'-117.283333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1426, N'Mont-Laurier', N'Québec', N'46.55', N'-75.5', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1427, N'Kenora', N'Ontario', N'49.766667', N'-94.466667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1428, N'Dawson Creek', N'British Columbia', N'55.766667', N'-120.233333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1429, N'Amos', N'Québec', N'48.566667', N'-78.116667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1430, N'Baie-Comeau', N'Québec', N'49.216667', N'-68.15', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1431, N'Hinton', N'Alberta', N'53.4', N'-117.583333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1432, N'Selkirk', N'Manitoba', N'50.15', N'-96.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1433, N'Steinbach', N'Manitoba', N'49.516667', N'-96.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1434, N'Weyburn', N'Saskatchewan', N'49.666667', N'-103.85', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1435, N'Amherst', N'Nova Scotia', N'45.830019', N'-64.210024', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1436, N'Kapuskasing', N'Ontario', N'49.416667', N'-82.433333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1437, N'Dauphin', N'Manitoba', N'51.15', N'-100.05', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1438, N'Dryden', N'Ontario', N'49.783333', N'-92.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1439, N'Revelstoke', N'British Columbia', N'51', N'-118.183333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1440, N'Happy Valley', N'Newfoundland and Labrador', N'53.3', N'-60.3', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1441, N'Banff', N'Alberta', N'51.166667', N'-115.566667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1442, N'Yarmouth', N'Nova Scotia', N'43.833965', N'-66.113926', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1443, N'La Sarre', N'Québec', N'48.8', N'-79.2', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1444, N'Parry Sound', N'Ontario', N'45.333333', N'-80.033333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1445, N'Stephenville', N'Newfoundland and Labrador', N'48.55', N'-58.566667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1446, N'Antigonish', N'Nova Scotia', N'45.616667', N'-61.966667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1447, N'Flin Flon', N'Manitoba', N'54.766667', N'-101.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1448, N'Fort Nelson', N'British Columbia', N'58.816667', N'-122.533333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1449, N'Smithers', N'British Columbia', N'54.766667', N'-127.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1450, N'Iqaluit', N'Nunavut', N'63.733333', N'-68.5', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1451, N'Bathurst', N'New Brunswick', N'47.558376', N'-65.656517', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1452, N'The Pas', N'Manitoba', N'53.816667', N'-101.233333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1453, N'Norway House', N'Manitoba', N'53.966667', N'-97.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1454, N'Meadow Lake', N'Saskatchewan', N'54.129722', N'-108.434722', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1455, N'Vegreville', N'Alberta', N'53.5', N'-112.05', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1456, N'Stettler', N'Alberta', N'52.333333', N'-112.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1457, N'Peace River', N'Alberta', N'56.233333', N'-117.283333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1458, N'New Liskeard', N'Ontario', N'47.5', N'-79.666667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1459, N'Hearst', N'Ontario', N'49.7', N'-83.666667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1460, N'Creston', N'British Columbia', N'49.1', N'-116.516667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1461, N'Marathon', N'Ontario', N'48.75', N'-86.366667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1462, N'Cochrane', N'Ontario', N'49.066667', N'-81.016667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1463, N'Kindersley', N'Saskatchewan', N'51.466667', N'-109.133333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1464, N'Liverpool', N'Nova Scotia', N'44.038414', N'-64.718433', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1465, N'Melville', N'Saskatchewan', N'50.933333', N'-102.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1466, N'Channel-Port aux Basques', N'Newfoundland and Labrador', N'47.566667', N'-59.15', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1467, N'Deer Lake', N'Newfoundland and Labrador', N'49.183333', N'-57.433333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1468, N'Saint-Augustin', N'Québec', N'51.233333', N'-58.65', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1469, N'Digby', N'Nova Scotia', N'44.578466', N'-65.783525', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1470, N'Jasper', N'Alberta', N'52.883333', N'-118.083333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1471, N'Hay River', N'Northwest Territories', N'60.85', N'-115.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1472, N'Windsor', N'Nova Scotia', N'44.958995', N'-64.144786', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1473, N'La Ronge', N'Saskatchewan', N'55.1', N'-105.3', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1474, N'Deer Lake', N'Ontario', N'52.616667', N'-94.066667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1475, N'Gaspé', N'Québec', N'48.833333', N'-64.483333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1476, N'Atikokan', N'Ontario', N'48.75', N'-91.616667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1477, N'Gander', N'Newfoundland and Labrador', N'48.95', N'-54.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1478, N'Fort Chipewyan', N'Alberta', N'58.716667', N'-111.15', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1479, N'Shelburne', N'Nova Scotia', N'43.753356', N'-65.246074', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1480, N'Inuvik', N'Northwest Territories', N'68.35', N'-133.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1481, N'Lac La Biche', N'Alberta', N'54.771944', N'-111.964722', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1482, N'Lillooet', N'British Columbia', N'50.683333', N'-121.933333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1483, N'Chapleau', N'Ontario', N'47.833333', N'-83.4', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1484, N'Burns Lake', N'British Columbia', N'54.216667', N'-125.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1485, N'Gimli', N'Manitoba', N'50.633333', N'-97', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1486, N'Athabasca', N'Alberta', N'54.716667', N'-113.266667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1487, N'Nelson House', N'Manitoba', N'55.8', N'-98.85', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1488, N'Rankin Inlet', N'Nunavut', N'62.816667', N'-92.083333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1489, N'Port Hardy', N'British Columbia', N'50.716667', N'-127.5', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1490, N'Biggar', N'Saskatchewan', N'52.05', N'-107.983333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1491, N'Wiarton', N'Ontario', N'44.733333', N'-81.133333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1492, N'Wawa', N'Ontario', N'47.99473', N'-84.77002', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1493, N'Hudson Bay', N'Saskatchewan', N'52.85', N'-102.383333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1494, N'Matagami', N'Québec', N'49.75', N'-77.633333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1495, N'Arviat', N'Nunavut', N'61.116667', N'-94.05', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1496, N'Attawapiskat', N'Ontario', N'52.916667', N'-82.433333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1497, N'Red Lake', N'Ontario', N'51.033333', N'-93.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1498, N'Moosonee', N'Ontario', N'51.266667', N'-80.65', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1499, N'Tofino', N'British Columbia', N'49.133333', N'-125.9', N'Canada')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1500, N'Igloolik', N'Nunavut', N'69.4', N'-81.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1501, N'Inukjuak', N'Québec', N'58.45334', N'-78.102493', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1502, N'Little Current', N'Ontario', N'45.966667', N'-81.933333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1503, N'Baker Lake', N'Nunavut', N'64.316667', N'-96.016667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1504, N'Pond Inlet', N'Nunavut', N'72.7', N'-78', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1505, N'Cap-Chat', N'Québec', N'49.083333', N'-66.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1506, N'Cambridge Bay', N'Nunavut', N'69.116667', N'-105.033333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1507, N'Thessalon', N'Ontario', N'46.25', N'-83.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1508, N'New Bella Bella', N'British Columbia', N'52.166667', N'-128.133333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1509, N'Cobalt', N'Ontario', N'47.383333', N'-79.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1510, N'Cape Dorset', N'Nunavut', N'64.233333', N'-76.55', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1511, N'Pangnirtung', N'Nunavut', N'66.133333', N'-65.75', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1512, N'West Dawson', N'Yukon', N'64.066667', N'-139.45', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1513, N'Kugluktuk', N'Nunavut', N'67.833333', N'-115.083333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1514, N'Geraldton', N'Ontario', N'49.716667', N'-86.966667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1515, N'Gillam', N'Manitoba', N'56.35', N'-94.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1516, N'Kuujjuaq', N'Québec', N'58.1', N'-68.4', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1517, N'Lake Louise', N'Alberta', N'51.433333', N'-116.183333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1518, N'Nipigon', N'Ontario', N'49.016667', N'-88.25', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1519, N'Nain', N'Newfoundland and Labrador', N'56.55', N'-61.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1520, N'Gjoa Haven', N'Nunavut', N'68.633333', N'-95.916667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1521, N'Fort McPherson', N'Northwest Territories', N'67.433333', N'-134.866667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1522, N'Argentia', N'Newfoundland and Labrador', N'47.3', N'-54', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1523, N'Norman Wells', N'Northwest Territories', N'65.283333', N'-126.85', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1524, N'Churchill', N'Manitoba', N'58.766667', N'-94.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1525, N'Repulse Bay', N'Nunavut', N'66.516667', N'-86.233333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1526, N'Tuktoyaktuk', N'Northwest Territories', N'69.45', N'-133.066667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1527, N'Berens River', N'Manitoba', N'52.366667', N'-97.033333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1528, N'Shamattawa', N'Manitoba', N'55.85', N'-92.083333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1529, N'Baddeck', N'Nova Scotia', N'46.1', N'-60.75', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1530, N'Coral Harbour', N'Nunavut', N'64.133333', N'-83.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1531, N'La Scie', N'Newfoundland and Labrador', N'49.966667', N'-55.583333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1532, N'Watson Lake', N'Yukon', N'60.116667', N'-128.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1533, N'Taloyoak', N'Nunavut', N'69.533333', N'-93.533333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1534, N'Natashquan', N'Québec', N'50.183333', N'-61.816667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1535, N'Buchans', N'Newfoundland and Labrador', N'48.816667', N'-56.866667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1536, N'Hall Beach', N'Nunavut', N'68.766667', N'-81.2', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1537, N'Arctic Bay', N'Nunavut', N'73.033333', N'-85.166667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1538, N'Fort Good Hope', N'Northwest Territories', N'66.266667', N'-128.633333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1539, N'Mingan', N'Québec', N'50.3', N'-64.016667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1540, N'Kangirsuk', N'Québec', N'60.016667', N'-70.033333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1541, N'Sandspit', N'British Columbia', N'53.239111', N'-131.818769', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1542, N'Déline', N'Northwest Territories', N'65.183333', N'-123.416667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1543, N'Fort Smith', N'Northwest Territories', N'60', N'-111.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1544, N'Cartwright', N'Newfoundland and Labrador', N'53.7', N'-57.016667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1545, N'Holman', N'Northwest Territories', N'70.733333', N'-117.75', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1546, N'Lynn Lake', N'Manitoba', N'56.85', N'-101.05', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1547, N'Schefferville', N'Québec', N'54.8', N'-66.816667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1548, N'Trout River', N'Newfoundland and Labrador', N'49.483333', N'-58.116667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1549, N'Forteau Bay', N'Newfoundland and Labrador', N'51.45', N'-56.95', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1550, N'Fort Resolution', N'Northwest Territories', N'61.166667', N'-113.683333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1551, N'Hopedale', N'Newfoundland and Labrador', N'55.45', N'-60.216667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1552, N'Pukatawagan', N'Manitoba', N'55.733333', N'-101.316667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1553, N'Trepassey', N'Newfoundland and Labrador', N'46.733333', N'-53.366667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1554, N'Kimmirut', N'Nunavut', N'62.85', N'-69.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1555, N'Chesterfield Inlet', N'Nunavut', N'63.333333', N'-90.7', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1556, N'Eastmain', N'Québec', N'52.233333', N'-78.516667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1557, N'Dease Lake', N'British Columbia', N'58.476697', N'-129.96146', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1558, N'Paulatuk', N'Northwest Territories', N'69.383333', N'-123.983333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1559, N'Fort Simpson', N'Northwest Territories', N'61.85', N'-121.333333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1560, N'Brochet', N'Manitoba', N'57.883333', N'-101.666667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1561, N'Cat Lake', N'Ontario', N'51.716667', N'-91.8', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1562, N'Radisson', N'Québec', N'53.783333', N'-77.616667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1563, N'Port-Menier', N'Québec', N'49.816667', N'-64.35', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1564, N'Resolute', N'Nunavut', N'74.683333', N'-94.9', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1565, N'Saint Anthony', N'Newfoundland and Labrador', N'51.383333', N'-55.6', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1566, N'Port Hope Simpson', N'Newfoundland and Labrador', N'52.533333', N'-56.3', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1567, N'Oxford House', N'Manitoba', N'54.95', N'-95.266667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1568, N'Tsiigehtchic', N'Northwest Territories', N'67.433333', N'-133.75', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1569, N'Ivujivik', N'Québec', N'62.416667', N'-77.9', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1570, N'Stony Rapids', N'Saskatchewan', N'59.266667', N'-105.833333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1571, N'Alert', N'Nunavut', N'82.483333', N'-62.25', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1572, N'Fort Severn', N'Ontario', N'55.983333', N'-87.65', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1573, N'Rigolet', N'Newfoundland and Labrador', N'54.166667', N'-58.433333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1574, N'Lansdowne House', N'Ontario', N'52.216667', N'-87.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1575, N'Salluit', N'Québec', N'62.2', N'-75.633333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1576, N'Lutselk’e', N'Northwest Territories', N'62.4', N'-110.733333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1577, N'Uranium City', N'Saskatchewan', N'59.566667', N'-108.616667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1578, N'Burwash Landing', N'Yukon', N'61.35', N'-139', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1579, N'Grise Fiord', N'Nunavut', N'76.416667', N'-82.95', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1580, N'Big Beaverhouse', N'Ontario', N'52.95', N'-89.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1581, N'Island Lake', N'Manitoba', N'53.966667', N'-94.766667', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1582, N'Ennadai', N'Nunavut', N'61.133333', N'-100.883333', N'Canada')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1583, N'Mumbai', N'Maharashtra', N'18.987807', N'72.836447', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1584, N'Delhi', N'Delhi', N'28.651952', N'77.231495', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1585, N'Kolkata', N'West Bengal', N'22.562627', N'88.363044', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1586, N'Chennai', N'Tamil Nadu ', N'13.084622', N'80.248357', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1587, N'Bengaluru', N'Karnataka', N'12.977063', N'77.587106', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1588, N'Hyderabad', N'Andhra Pradesh', N'17.384052', N'78.456355', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1589, N'Ahmadabad', N'Gujarat', N'23.025793', N'72.587265', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1590, N'Haora', N'West Bengal', N'22.576882', N'88.318566', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1591, N'Pune', N'Maharashtra', N'18.513271', N'73.849852', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1592, N'Surat', N'Gujarat', N'21.195944', N'72.830232', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1593, N'Mardanpur', N'Uttar Pradesh', N'26.430066', N'80.267176', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1594, N'Rampura', N'Rajasthan', N'26.884682', N'75.789336', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1595, N'Lucknow', N'Uttar Pradesh', N'26.839281', N'80.923133', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1596, N'Nara', N'Maharashtra', N'21.203096', N'79.089284', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1597, N'Patna', N'Bihar', N'25.615379', N'85.101027', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1598, N'Indore', N'Madhya Pradesh', N'22.717736', N'75.85859', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1599, N'Vadodara', N'Gujarat', N'22.299405', N'73.208119', N'India')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1600, N'Bhopal', N'Madhya Pradesh', N'23.254688', N'77.402892', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1601, N'Coimbatore', N'Tamil Nadu ', N'11.005547', N'76.966122', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1602, N'Ludhiana', N'Punjab', N'30.912042', N'75.853789', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1603, N'agra', N'Uttar Pradesh', N'27.187935', N'78.003944', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1604, N'Kalyan', N'Maharashtra', N'19.243703', N'73.135537', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1605, N'Vishakhapatnam', N'Andhra Pradesh', N'17.704052', N'83.297663', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1606, N'Kochi', N'Kerala', N'9.947743', N'76.253802', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1607, N'Nasik', N'Maharashtra', N'19.999963', N'73.776887', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1608, N'Meerut', N'Uttar Pradesh', N'28.980018', N'77.706356', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1609, N'Faridabad', N'Haryana', N'28.411236', N'77.313162', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1610, N'Varanasi', N'Uttar Pradesh', N'25.31774', N'83.005811', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1611, N'Ghaziabad', N'Uttar Pradesh', N'28.665353', N'77.439148', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1612, N'asansol', N'West Bengal', N'23.683333', N'86.983333', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1613, N'Jamshedpur', N'Jharkhand', N'22.802776', N'86.185448', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1614, N'Madurai', N'Tamil Nadu ', N'9.917347', N'78.119622', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1615, N'Jabalpur', N'Madhya Pradesh', N'23.174495', N'79.935903', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1616, N'Rajkot', N'Gujarat', N'22.291606', N'70.793217', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1617, N'Dhanbad', N'Jharkhand', N'23.801988', N'86.443244', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1618, N'Amritsar', N'Punjab', N'31.622337', N'74.875335', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1619, N'Warangal', N'Andhra Pradesh', N'17.978423', N'79.600209', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1620, N'Allahabad', N'Uttar Pradesh', N'25.44478', N'81.843217', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1621, N'Srinagar', N'Jammu and Kashmir', N'34.085652', N'74.805553', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1622, N'Aurangabad', N'Maharashtra', N'19.880943', N'75.346739', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1623, N'Bhilai', N'Chhattisgarh', N'21.209188', N'81.428497', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1624, N'Solapur', N'Maharashtra', N'17.671523', N'75.910437', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1625, N'Ranchi', N'Jharkhand', N'23.347768', N'85.338564', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1626, N'Jodhpur', N'Rajasthan', N'26.26841', N'73.005943', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1627, N'Guwahati', N'Assam', N'26.176076', N'91.762932', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1628, N'Chandigarh', N'Chandigarh', N'30.736292', N'76.788398', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1629, N'Gwalior', N'Madhya Pradesh', N'26.229825', N'78.173369', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1630, N'Thiruvananthapuram', N'Kerala', N'8.485498', N'76.949238', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1631, N'Tiruchchirappalli', N'Tamil Nadu ', N'10.815499', N'78.696513', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1632, N'Hubli', N'Karnataka', N'15.349955', N'75.138619', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1633, N'Mysore', N'Karnataka', N'12.292664', N'76.638543', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1634, N'Raipur', N'Chhattisgarh', N'21.233333', N'81.633333', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1635, N'Salem', N'Tamil Nadu ', N'11.651165', N'78.158672', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1636, N'Bhubaneshwar', N'Odisha', N'20.272411', N'85.833853', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1637, N'Kota', N'Rajasthan', N'25.182544', N'75.839065', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1638, N'Jhansi', N'Uttar Pradesh', N'25.458872', N'78.579943', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1639, N'Bareilly', N'Uttar Pradesh', N'28.347023', N'79.421934', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1640, N'Aligarh', N'Uttar Pradesh', N'27.881453', N'78.07464', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1641, N'Bhiwandi', N'Maharashtra', N'19.300229', N'73.058813', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1642, N'Jammu', N'Jammu and Kashmir', N'32.735686', N'74.869112', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1643, N'Moradabad', N'Uttar Pradesh', N'28.838931', N'78.776838', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1644, N'Mangalore', N'Karnataka', N'12.865371', N'74.842432', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1645, N'Kolhapur', N'Maharashtra', N'16.695633', N'74.231669', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1646, N'Amravati', N'Maharashtra', N'20.933272', N'77.75152', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1647, N'Dehra Dun', N'Uttarakhand', N'30.324427', N'78.033922', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1648, N'Malegaon Camp', N'Maharashtra', N'20.569974', N'74.515415', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1649, N'Nellore', N'Andhra Pradesh', N'14.449918', N'79.986967', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1650, N'Gopalpur', N'Uttar Pradesh', N'26.735389', N'83.38064', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1651, N'Shimoga', N'Karnataka', N'13.932424', N'75.572555', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1652, N'Tiruppur', N'Tamil Nadu ', N'11.104096', N'77.346402', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1653, N'Raurkela', N'Odisha', N'22.224964', N'84.864143', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1654, N'Nanded', N'Maharashtra', N'19.160227', N'77.314971', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1655, N'Belgaum', N'Karnataka', N'15.862643', N'74.508534', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1656, N'Sangli', N'Maharashtra', N'16.856777', N'74.569196', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1657, N'Chanda', N'Maharashtra', N'19.950758', N'79.295229', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1658, N'Ajmer', N'Rajasthan', N'26.452103', N'74.638667', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1659, N'Cuttack', N'Odisha', N'20.522922', N'85.78813', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1660, N'Bikaner', N'Rajasthan', N'28.017623', N'73.314955', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1661, N'Bhavnagar', N'Gujarat', N'21.774455', N'72.152496', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1662, N'Hisar', N'Haryana', N'29.153938', N'75.722944', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1663, N'Bilaspur', N'Chhattisgarh', N'22.080046', N'82.155431', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1664, N'Tirunelveli', N'Tamil Nadu ', N'8.725181', N'77.684519', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1665, N'Guntur', N'Andhra Pradesh', N'16.299737', N'80.457293', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1666, N'Shiliguri', N'West Bengal', N'26.710035', N'88.428512', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1667, N'Ujjain', N'Madhya Pradesh', N'23.182387', N'75.776433', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1668, N'Davangere', N'Karnataka', N'14.469237', N'75.92375', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1669, N'Akola', N'Maharashtra', N'20.709569', N'76.998103', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1670, N'Saharanpur', N'Uttar Pradesh', N'29.967896', N'77.545221', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1671, N'Gulbarga', N'Karnataka', N'17.335827', N'76.83757', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1672, N'Bhatpara', N'West Bengal', N'22.866431', N'88.401129', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1673, N'Dhulia', N'Maharashtra', N'20.901299', N'74.777373', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1674, N'Udaipur', N'Rajasthan', N'24.57951', N'73.690508', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1675, N'Bellary', N'Karnataka', N'15.142049', N'76.92398', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1676, N'Tuticorin', N'Tamil Nadu ', N'8.805038', N'78.151884', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1677, N'Kurnool', N'Andhra Pradesh', N'15.828865', N'78.036021', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1678, N'Gaya', N'Bihar', N'24.796858', N'85.003852', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1679, N'Sikar', N'Rajasthan', N'27.614778', N'75.138671', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1680, N'Tumkur', N'Karnataka', N'13.341358', N'77.102203', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1681, N'Kollam', N'Kerala', N'8.881131', N'76.584694', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1682, N'Ahmadnagar', N'Maharashtra', N'19.094571', N'74.738432', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1683, N'Bhilwara', N'Rajasthan', N'25.347071', N'74.640812', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1684, N'Nizamabad', N'Andhra Pradesh', N'18.673151', N'78.10008', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1685, N'Parbhani', N'Maharashtra', N'19.268553', N'76.770807', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1686, N'Shillong', N'Meghalaya', N'25.573987', N'91.896807', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1687, N'Latur', N'Maharashtra', N'18.399487', N'76.584252', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1688, N'Rajapalaiyam', N'Tamil Nadu ', N'9.451111', N'77.556121', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1689, N'Bhagalpur', N'Bihar', N'25.244462', N'86.971832', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1690, N'Muzaffarnagar', N'Uttar Pradesh', N'29.470914', N'77.703324', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1691, N'Muzaffarpur', N'Bihar', N'26.122593', N'85.390553', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1692, N'Mathura', N'Uttar Pradesh', N'27.503501', N'77.672145', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1693, N'Patiala', N'Punjab', N'30.336245', N'76.392199', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1694, N'Saugor', N'Madhya Pradesh', N'23.838766', N'78.738738', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1695, N'Brahmapur', N'Odisha', N'19.311514', N'84.792903', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1696, N'Shahbazpur', N'Uttar Pradesh', N'27.874116', N'79.879327', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1697, N'New Delhi', N'Delhi', N'28.6', N'77.2', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1698, N'Rohtak', N'Haryana', N'28.894473', N'76.589166', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1699, N'Samlaipadar', N'Odisha', N'21.478072', N'83.990505', N'India')
GO
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1700, N'Ratlam', N'Madhya Pradesh', N'23.330331', N'75.040315', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1701, N'Firozabad', N'Uttar Pradesh', N'27.150917', N'78.397808', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1702, N'Rajahmundry', N'Andhra Pradesh', N'17.005171', N'81.777839', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1703, N'Barddhaman', N'West Bengal', N'23.255716', N'87.856906', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1704, N'Bidar', N'Karnataka', N'17.913309', N'77.530105', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1705, N'Bamanpuri', N'Uttar Pradesh', N'28.804495', N'79.040305', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1706, N'Kakinada', N'Andhra Pradesh', N'16.960361', N'82.238086', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1707, N'Panipat', N'Haryana', N'29.387471', N'76.968246', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1708, N'Khammam', N'Andhra Pradesh', N'17.247672', N'80.143682', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1709, N'Bhuj', N'Gujarat', N'23.253972', N'69.669281', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1710, N'Karimnagar', N'Andhra Pradesh', N'18.436738', N'79.13222', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1711, N'Tirupati', N'Andhra Pradesh', N'13.635505', N'79.419888', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1712, N'Hospet', N'Karnataka', N'15.269537', N'76.387103', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1713, N'Chikka Mandya', N'Karnataka', N'12.545602', N'76.895078', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1714, N'Alwar', N'Rajasthan', N'27.566291', N'76.610202', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1715, N'Aizawl', N'Mizoram', N'23.736701', N'92.714596', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1716, N'Bijapur', N'Karnataka', N'16.827715', N'75.718988', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1717, N'Imphal', N'Manipur', N'24.808053', N'93.944203', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1718, N'Tharati Etawah', N'Uttar Pradesh', N'26.758236', N'79.014875', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1719, N'Raichur', N'Karnataka', N'16.205459', N'77.35567', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1720, N'Pathankot', N'Punjab', N'32.274842', N'75.652865', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1721, N'Chirala', N'Andhra Pradesh', N'15.823849', N'80.352187', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1722, N'Sonipat', N'Haryana', N'28.994778', N'77.019375', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1723, N'Mirzapur', N'Uttar Pradesh', N'25.144902', N'82.565335', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1724, N'Hapur', N'Uttar Pradesh', N'28.729845', N'77.780681', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1725, N'Porbandar', N'Gujarat', N'21.641346', N'69.600868', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1726, N'Bharatpur', N'Rajasthan', N'27.215251', N'77.492786', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1727, N'Puducherry', N'Puducherry', N'11.933812', N'79.829792', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1728, N'Karnal', N'Haryana', N'29.691971', N'76.984483', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1729, N'Nagercoil', N'Tamil Nadu ', N'8.177313', N'77.43437', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1730, N'Thanjavur', N'Tamil Nadu ', N'10.785233', N'79.139093', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1731, N'Pali', N'Rajasthan', N'25.775125', N'73.320611', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1732, N'Agartala', N'Tripura', N'23.836049', N'91.279386', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1733, N'Ongole', N'Andhra Pradesh', N'15.503565', N'80.044541', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1734, N'Puri', N'Odisha', N'19.798254', N'85.824938', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1735, N'Dindigul', N'Tamil Nadu ', N'10.362853', N'77.975827', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1736, N'Haldia', N'West Bengal', N'22.025278', N'88.058333', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1737, N'Bulandshahr', N'Uttar Pradesh', N'28.403922', N'77.857731', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1738, N'Purnea', N'Bihar', N'25.776703', N'87.473655', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1739, N'Proddatur', N'Andhra Pradesh', N'14.7502', N'78.548129', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1740, N'Gurgaon', N'Haryana', N'28.460105', N'77.026352', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1741, N'Khanapur', N'Maharashtra', N'21.273716', N'76.117376', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1742, N'Machilipatnam', N'Andhra Pradesh', N'16.187466', N'81.13888', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1743, N'Bhiwani', N'Haryana', N'28.793044', N'76.13968', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1744, N'Nandyal', N'Andhra Pradesh', N'15.477994', N'78.483605', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1745, N'Bhusaval', N'Maharashtra', N'21.043649', N'75.785058', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1746, N'Bharauri', N'Uttar Pradesh', N'27.598203', N'81.694709', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1747, N'Tonk', N'Rajasthan', N'26.168672', N'75.786111', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1748, N'Sirsa', N'Haryana', N'29.534893', N'75.028981', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1749, N'Vizianagaram', N'Andhra Pradesh', N'18.11329', N'83.397743', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1750, N'Vellore', N'Tamil Nadu ', N'12.905769', N'79.137104', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1751, N'Alappuzha', N'Kerala', N'9.494647', N'76.331108', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1752, N'Shimla', N'Himachal Pradesh', N'31.104423', N'77.166623', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1753, N'Hindupur', N'Andhra Pradesh', N'13.828065', N'77.491425', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1754, N'Baramula', N'Jammu and Kashmir', N'34.209004', N'74.342853', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1755, N'Bakshpur', N'Uttar Pradesh', N'25.894283', N'80.792104', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1756, N'Dibrugarh', N'Assam', N'27.479888', N'94.90837', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1757, N'Saidapur', N'Uttar Pradesh', N'27.598784', N'80.75089', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1758, N'Navsari', N'Gujarat', N'20.85', N'72.916667', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1759, N'Budaun', N'Uttar Pradesh', N'28.038114', N'79.126677', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1760, N'Cuddalore', N'Tamil Nadu ', N'11.746289', N'79.764362', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1761, N'Haripur', N'Punjab', N'31.463218', N'75.986418', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1762, N'Krishnapuram', N'Tamil Nadu ', N'12.869617', N'79.719469', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1763, N'Fyzabad', N'Uttar Pradesh', N'26.775486', N'82.150182', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1764, N'Silchar', N'Assam', N'24.827327', N'92.797868', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1765, N'Ambala', N'Haryana', N'30.360993', N'76.797819', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1766, N'Krishnanagar', N'West Bengal', N'23.405761', N'88.490733', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1767, N'Kolar', N'Karnataka', N'13.137679', N'78.129989', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1768, N'Kumbakonam', N'Tamil Nadu ', N'10.959789', N'79.377472', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1769, N'Tiruvannamalai', N'Tamil Nadu ', N'12.230204', N'79.072954', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1770, N'Pilibhit', N'Uttar Pradesh', N'28.631245', N'79.804362', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1771, N'Abohar', N'Punjab', N'30.144533', N'74.19552', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1772, N'Port Blair', N'Andaman and Nicobar Islands', N'11.666667', N'92.75', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1773, N'Alipur Duar', N'West Bengal', N'26.4835', N'89.522855', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1774, N'Hatisa', N'Uttar Pradesh', N'27.592698', N'78.013843', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1775, N'Valparai', N'Tamil Nadu ', N'10.325163', N'76.955299', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1776, N'Aurangabad', N'Bihar', N'24.752037', N'84.374202', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1777, N'Kohima', N'Nagaland', N'25.674673', N'94.110988', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1778, N'Gangtok', N'Sikkim', N'27.325739', N'88.612155', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1779, N'Karur', N'Tamil Nadu ', N'10.960277', N'78.076753', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1780, N'Jorhat', N'Assam', N'26.757509', N'94.203055', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1781, N'Panaji', N'Goa', N'15.498289', N'73.824541', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1782, N'Saidpur', N'Jammu and Kashmir', N'34.318174', N'74.457093', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1783, N'Tezpur', N'Assam', N'26.633333', N'92.8', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1784, N'Itanagar', N'Arunachal Pradesh', N'27.102349', N'93.692047', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1785, N'Daman', N'Daman and Diu', N'20.414315', N'72.83236', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1786, N'Silvassa', N'Dadra and Nagar Haveli', N'20.273855', N'72.996728', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1787, N'Diu', N'Daman and Diu', N'20.715115', N'70.987952', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1788, N'Dispur', N'Assam', N'26.135638', N'91.800688', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1789, N'Kavaratti', N'Lakshadweep', N'10.566667', N'72.616667', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1790, N'Calicut', N'Kerala', N'11.248016', N'75.780402', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1791, N'Kagaznagar', N'Andhra Pradesh', N'19.331589', N'79.466051', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1792, N'Jaipur', N'Rajasthan', N'26.913312', N'75.787872', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1793, N'Ghandinagar', N'Gujarat', N'23.216667', N'72.683333', N'India')
INSERT [dbo].[lkpAllCities] ([CityId], [CityName], [StateName], [Latitude], [Longitude], [CountryName]) VALUES (1794, N'Panchkula', N'Haryana', N'30.691512', N'76.853736', N'India')
SET IDENTITY_INSERT [dbo].[lkpAllCities] OFF
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AE', N'23.424076', N'53.847818', N'United Arab Emirates', 784)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AF', N'33.93911', N'67.709953', N'Afghanistan', 4)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AG', N'17.060816', N'-61.796428', N'Antigua and Barbuda', 28)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AI', N'18.220554', N'-63.068615', N'Anguilla', 31)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AL', N'41.153332', N'20.168331', N'Albania', 8)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AM', N'40.069099', N'45.038189', N'Armenia', 51)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AN', N'12.226079', N'-69.060087', N'Netherlands Antilles', 528)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AND', N'42.546245', N'1.601554', N'Andorra', 20)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AO', N'-11.202692', N'17.873887', N'Angola', 24)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AQ', N'-75.250973', N'-0.071389', N'Antarctica', 10)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AR', N'-38.416097', N'-63.616672', N'Argentina', 32)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AS', N'-14.270972', N'-170.132217', N'American Samoa', 16)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AT', N'47.516231', N'14.550072', N'Austria', 40)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AU', N'-25.274398', N'133.775136', N'Australia', 36)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AW', N'12.52111', N'-69.968338', N'Aruba', 533)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'AZ', N'40.143105', N'47.576927', N'Azerbaijan', 31)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BA', N'43.915886', N'17.679076', N'Bosnia and Herzegovina', 70)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BB', N'13.193887', N'-59.543198', N'Barbados', 52)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BD', N'23.684994', N'90.356331', N'Bangladesh', 50)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BE', N'50.503887', N'4.469936', N'Belgium', 56)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BF', N'12.238333', N'-1.561593', N'Burkina Faso', 854)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BG', N'42.733883', N'25.48583', N'Bulgaria', 100)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BH', N'25.930414', N'50.637772', N'Bahrain', 48)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BI', N'-3.373056', N'29.918886', N'Burundi', 108)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BJ', N'9.30769', N'2.315834', N'Benin', 204)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BM', N'32.321384', N'-64.75737', N'Bermuda', 60)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BN', N'4.535277', N'114.727669', N'Brunei', 96)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BO', N'-16.290154', N'-63.588653', N'Bolivia', 68)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BR', N'-14.235004', N'-51.92528', N'Brazil', 76)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BS', N'25.03428', N'-77.39628', N'Bahamas', 44)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BT', N'27.514162', N'90.433601', N'Bhutan', 64)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BV', N'-54.423199', N'3.413194', N'Bouvet Island', 74)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BW', N'-22.328474', N'24.684866', N'Botswana', 72)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BY', N'53.709807', N'27.953389', N'Belarus', 112)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'BZ', N'17.189877', N'-88.49765', N'Belize', 84)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CA', N'56.130366', N'-106.346771', N'Canada', 124)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CC', N'-12.164165', N'96.870956', N'Cocos [Keeling] Islands', 166)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CD', N'-4.038333', N'21.758664', N'Congo [DRC]', 178)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CF', N'6.611111', N'20.939444', N'Central African Republic', 140)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CG', N'-0.228021', N'15.827659', N'Congo [Republic]', 180)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CH', N'46.818188', N'8.227512', N'Switzerland', 756)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CI', N'7.539989', N'-5.54708', N'Côte d''Ivoire', 384)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CK', N'-21.236736', N'-159.777671', N'Cook Islands', 184)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CL', N'-35.675147', N'-71.542969', N'Chile', 152)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CM', N'7.369722', N'12.354722', N'Cameroon', 120)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CN', N'35.86166', N'104.195397', N'China', 156)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CO', N'4.570868', N'-74.297333', N'Colombia', 170)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CR', N'9.748917', N'-83.753428', N'Costa Rica', 188)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CU', N'21.521757', N'-77.781167', N'Cuba', 192)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CV', N'16.002082', N'-24.013197', N'Cape Verde', 132)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CX', N'-10.447525', N'105.690449', N'Christmas Island', 162)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CY', N'35.126413', N'33.429859', N'Cyprus', 196)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'CZ', N'49.817492', N'15.472962', N'Czech Republic', 203)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DE', N'51.165691', N'10.451526', N'Germany', 276)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DJ', N'11.825138', N'42.590275', N'Djibouti', 262)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DK', N'56.26392', N'9.501785', N'Denmark', 208)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DM', N'15.414999', N'-61.370976', N'Dominica', 212)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DO', N'18.735693', N'-70.162651', N'Dominican Republic', 214)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'DZ', N'28.033886', N'1.659626', N'Algeria', 12)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'EC', N'-1.831239', N'-78.183406', N'Ecuador', 218)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'EE', N'58.595272', N'25.013607', N'Estonia', 233)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'EG', N'26.820553', N'30.802498', N'Egypt', 818)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'EH', N'24.215527', N'-12.885834', N'Western Sahara', 732)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ER', N'15.179384', N'39.782334', N'Eritrea', 232)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ES', N'40.463667', N'-3.74922', N'Spain', 724)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ET', N'9.145', N'40.489673', N'Ethiopia', 231)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FI', N'61.92411', N'25.748151', N'Finland', 246)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FJ', N'-16.578193', N'179.414413', N'Fiji', 242)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FK', N'-51.796253', N'-59.523613', N'Falkland Islands [Islas Malvinas]', 238)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FM', N'7.425554', N'150.550812', N'Micronesia', 583)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FO', N'61.892635', N'-6.911806', N'Faroe Islands', 234)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'FR', N'46.227638', N'2.213749', N'France', 250)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GA', N'-0.803689', N'11.609444', N'Gabon', 266)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GB', N'55.378051', N'-3.435973', N'United Kingdom', 826)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GD', N'12.262776', N'-61.604171', N'Grenada', 308)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GE', N'42.315407', N'43.356892', N'Georgia', 268)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GF', N'3.933889', N'-53.125782', N'French Guiana', 254)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GG', N'49.465691', N'-2.585278', N'Guernsey', 831)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GH', N'7.946527', N'-1.023194', N'Ghana', 288)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GI', N'36.137741', N'-5.345374', N'Gibraltar', 292)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GL', N'71.706936', N'-42.604303', N'Greenland', 304)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GM', N'13.443182', N'-15.310139', N'Gambia', 270)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GN', N'9.945587', N'-9.696645', N'Guinea', 226)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GP', N'16.995971', N'-62.067641', N'Guadeloupe', 312)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GQ', N'1.650801', N'10.267895', N'Equatorial Guinea', 226)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GR', N'39.074208', N'21.824312', N'Greece', 300)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GS', N'-54.429579', N'-36.587909', N'South Georgia and the South Sandwich Islands', 239)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GT', N'15.783471', N'-90.230759', N'Guatemala', 320)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GU', N'13.444304', N'144.793731', N'Guam', 316)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GW', N'11.803749', N'-15.180413', N'Guinea-Bissau', 624)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GY', N'4.860416', N'-58.93018', N'Guyana', 328)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'GZ', N'31.354676', N'34.308825', N'Gaza Strip', NULL)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HK', N'22.396428', N'114.109497', N'Hong Kong', 344)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HM', N'-53.08181', N'73.504158', N'Heard Island and McDonald Islands', 334)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HN', N'15.199999', N'-86.241905', N'Honduras', 340)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HR', N'45.1', N'15.2', N'Croatia', 191)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HT', N'18.971187', N'-72.285215', N'Haiti', 332)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'HU', N'47.162494', N'19.503304', N'Hungary', 348)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ID', N'-0.789275', N'113.921327', N'Indonesia', 360)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IE', N'53.41291', N'-8.24389', N'Ireland', 372)
GO
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IL', N'31.046051', N'34.851612', N'Israel', 376)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IM', N'54.236107', N'-4.548056', N'Isle of Man', 833)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IN', N'20.593684', N'78.96288', N'India', 356)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IO', N'-6.343194', N'71.876519', N'British Indian Ocean Territory', 86)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IQ', N'33.223191', N'43.679291', N'Iraq', 368)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IR', N'32.427908', N'53.688046', N'Iran', 364)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IS', N'64.963051', N'-19.020835', N'Iceland', 352)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'IT', N'41.87194', N'12.56738', N'Italy', 380)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'JE', N'49.214439', N'-2.13125', N'Jersey', 832)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'JM', N'18.109581', N'-77.297508', N'Jamaica', 388)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'JO', N'30.585164', N'36.238414', N'Jordan', 400)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'JP', N'36.204824', N'138.252924', N'Japan', 392)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KE', N'-0.023559', N'37.906193', N'Kenya', 404)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KG', N'41.20438', N'74.766098', N'Kyrgyzstan', 417)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KH', N'12.565679', N'104.990963', N'Cambodia', 116)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KI', N'-3.370417', N'-168.734039', N'Kiribati', 296)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KM', N'-11.875001', N'43.872219', N'Comoros', 174)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KN', N'17.357822', N'-62.782998', N'Saint Kitts and Nevis', 659)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KP', N'40.339852', N'127.510093', N'North Korea', 408)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KR', N'35.907757', N'127.766922', N'South Korea', 410)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KW', N'29.31166', N'47.481766', N'Kuwait', 414)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KY', N'19.513469', N'-80.566956', N'Cayman Islands', 136)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'KZ', N'48.019573', N'66.923684', N'Kazakhstan', 398)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LA', N'19.85627', N'102.495496', N'Laos', 418)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LB', N'33.854721', N'35.862285', N'Lebanon', 422)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LC', N'13.909444', N'-60.978893', N'Saint Lucia', 662)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LI', N'47.166', N'9.555373', N'Liechtenstein', 438)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LK', N'7.873054', N'80.771797', N'Sri Lanka', 144)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LR', N'6.428055', N'-9.429499', N'Liberia', 430)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LS', N'-29.609988', N'28.233608', N'Lesotho', 426)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LT', N'55.169438', N'23.881275', N'Lithuania', 440)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LU', N'49.815273', N'6.129583', N'Luxembourg', 442)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LV', N'56.879635', N'24.603189', N'Latvia', 428)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'LY', N'26.3351', N'17.228331', N'Libya', 434)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MA', N'31.791702', N'-7.09262', N'Morocco', 504)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MC', N'43.750298', N'7.412841', N'Monaco', 492)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MD', N'47.411631', N'28.369885', N'Moldova', 498)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ME', N'42.708678', N'19.37439', N'Montenegro', 499)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MG', N'-18.766947', N'46.869107', N'Madagascar', 450)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MH', N'7.131474', N'171.184478', N'Marshall Islands', 584)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MK', N'41.608635', N'21.745275', N'Macedonia [FYROM]', 807)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ML', N'17.570692', N'-3.996166', N'Mali', 466)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MM', N'21.913965', N'95.956223', N'Myanmar [Burma]', 104)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MN', N'46.862496', N'103.846656', N'Mongolia', 496)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MO', N'22.198745', N'113.543873', N'Macau', 446)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MP', N'17.33083', N'145.38469', N'Northern Mariana Islands', 580)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MQ', N'14.641528', N'-61.024174', N'Martinique', 474)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MR', N'21.00789', N'-10.940835', N'Mauritania', 478)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MS', N'16.742498', N'-62.187366', N'Montserrat', 500)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MT', N'35.937496', N'14.375416', N'Malta', 470)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MU', N'-20.348404', N'57.552152', N'Mauritius', 480)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MV', N'3.202778', N'73.22068', N'Maldives', 462)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MW', N'-13.254308', N'34.301525', N'Malawi', 454)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MX', N'23.634501', N'-102.552784', N'Mexico', 484)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MY', N'4.210484', N'101.975766', N'Malaysia', 458)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'MZ', N'-18.665695', N'35.529562', N'Mozambique', 508)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NA', N'-22.95764', N'18.49041', N'Namibia', 516)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NC', N'-20.904305', N'165.618042', N'New Caledonia', 540)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NE', N'17.607789', N'8.081666', N'Niger', 562)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NF', N'-29.040835', N'167.954712', N'Norfolk Island', 574)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NG', N'9.081999', N'8.675277', N'Nigeria', 566)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NI', N'12.865416', N'-85.207229', N'Nicaragua', 558)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NL', N'52.132633', N'5.291266', N'Netherlands', 528)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NO', N'60.472024', N'8.468946', N'Norway', 578)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NP', N'28.394857', N'84.124008', N'Nepal', 524)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NR', N'-0.522778', N'166.931503', N'Nauru', 520)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NU', N'-19.054445', N'-169.867233', N'Niue', 570)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'NZ', N'-40.900557', N'174.885971', N'New Zealand', 554)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'OM', N'21.512583', N'55.923255', N'Oman', 512)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PA', N'8.537981', N'-80.782127', N'Panama', 591)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PE', N'-9.189967', N'-75.015152', N'Peru', 604)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PF', N'-17.679742', N'-149.406843', N'French Polynesia', 258)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PG', N'-6.314993', N'143.95555', N'Papua New Guinea', 598)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PH', N'12.879721', N'121.774017', N'Philippines', 608)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PK', N'30.375321', N'69.345116', N'Pakistan', 586)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PL', N'51.919438', N'19.145136', N'Poland', 616)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PM', N'46.941936', N'-56.27111', N'Saint Pierre and Miquelon', 666)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PN', N'-24.703615', N'-127.439308', N'Pitcairn Islands', 612)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PR', N'18.220833', N'-66.590149', N'Puerto Rico', 630)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PS', N'31.952162', N'35.233154', N'Palestinian Territories', 275)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PT', N'39.399872', N'-8.224454', N'Portugal', 620)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PW', N'7.51498', N'134.58252', N'Palau', 585)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'PY', N'-23.442503', N'-58.443832', N'Paraguay', 600)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'QA', N'25.354826', N'51.183884', N'Qatar', 634)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'RE', N'-21.115141', N'55.536384', N'Réunion', 638)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'RO', N'45.943161', N'24.96676', N'Romania', 642)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'RS', N'44.016521', N'21.005859', N'Serbia', 688)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'RU', N'61.52401', N'105.318756', N'Russia', 643)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'RW', N'-1.940278', N'29.873888', N'Rwanda', 646)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SA', N'23.885942', N'45.079162', N'Saudi Arabia', 682)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SB', N'-9.64571', N'160.156194', N'Solomon Islands', 90)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SC', N'-4.679574', N'55.491977', N'Seychelles', 690)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SD', N'12.862807', N'30.217636', N'Sudan', 729)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SE', N'60.128161', N'18.643501', N'Sweden', 752)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SG', N'1.352083', N'103.819836', N'Singapore', 702)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SH', N'-24.143474', N'-10.030696', N'Saint Helena', 654)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SI', N'46.151241', N'14.995463', N'Slovenia', 705)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SJ', N'77.553604', N'23.670272', N'Svalbard and Jan Mayen', 744)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SK', N'48.669026', N'19.699024', N'Slovakia', 703)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SL', N'8.460555', N'-11.779889', N'Sierra Leone', 694)
GO
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SM', N'43.94236', N'12.457777', N'San Marino', 674)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SN', N'14.497401', N'-14.452362', N'Senegal', 686)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SO', N'5.152149', N'46.199616', N'Somalia', 706)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SR', N'3.919305', N'-56.027783', N'Suriname', 740)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ST', N'0.18636', N'6.613081', N'São Tomé and Príncipe', 678)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SV', N'13.794185', N'-88.89653', N'El Salvador', 222)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SY', N'34.802075', N'38.996815', N'Syria', 760)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'SZ', N'-26.522503', N'31.465866', N'Swaziland', 748)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TC', N'21.694025', N'-71.797928', N'Turks and Caicos Islands', 796)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TD', N'15.454166', N'18.732207', N'Chad', 148)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TF', N'-49.280366', N'69.348557', N'French Southern Territories', 260)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TG', N'8.619543', N'0.824782', N'Togo', 768)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TH', N'15.870032', N'100.992541', N'Thailand', 764)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TJ', N'38.861034', N'71.276093', N'Tajikistan', 762)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TK', N'-8.967363', N'-171.855881', N'Tokelau', 772)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TL', N'-8.874217', N'125.727539', N'Timor-Leste', 626)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TM', N'38.969719', N'59.556278', N'Turkmenistan', 795)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TN', N'33.886917', N'9.537499', N'Tunisia', 788)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TO', N'-21.178986', N'-175.198242', N'Tonga', 776)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TR', N'38.963745', N'35.243322', N'Turkey', 792)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TT', N'10.691803', N'-61.222503', N'Trinidad and Tobago', 780)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TV', N'-7.109535', N'177.64933', N'Tuvalu', 798)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TW', N'23.69781', N'120.960515', N'Taiwan', 158)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'TZ', N'-6.369028', N'34.888822', N'Tanzania', 834)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'UA', N'48.379433', N'31.16558', N'Ukraine', 804)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'UG', N'1.373333', N'32.290275', N'Uganda', 800)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'UM', N'', N'', N'U.S. Minor Outlying Islands', 850)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'US', N'37.09024', N'-95.712891', N'United States', 840)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'UY', N'-32.522779', N'-55.765835', N'Uruguay', 858)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'UZ', N'41.377491', N'64.585262', N'Uzbekistan', 860)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VA', N'41.902916', N'12.453389', N'Vatican City', 336)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VC', N'12.984305', N'-61.287228', N'Saint Vincent and the Grenadines', 670)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VE', N'6.42375', N'-66.58973', N'Venezuela', 862)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VG', N'18.420695', N'-64.639968', N'British Virgin Islands', 86)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VI', N'18.335765', N'-64.896335', N'U.S. Virgin Islands', 850)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VN', N'14.058324', N'108.277199', N'Vietnam', 704)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'VU', N'-15.376706', N'166.959158', N'Vanuatu', 548)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'WF', N'-13.768752', N'-177.156097', N'Wallis and Futuna', 876)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'WS', N'-13.759029', N'-172.104629', N'Samoa', 882)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'XK', N'42.602636', N'20.902977', N'Kosovo', 2)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'YE', N'15.552727', N'48.516388', N'Yemen', 887)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'YT', N'-12.8275', N'45.166244', N'Mayotte', 175)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ZA', N'-30.559482', N'22.937506', N'South Africa', 710)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ZM', N'-13.133897', N'27.849332', N'Zambia', 894)
INSERT [dbo].[lkpAllCountries] ([CountryCode], [latitude], [longitude], [CountryName], [MapId]) VALUES (N'ZW', N'-19.015438', N'29.154857', N'Zimbabwe', 716)
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Alabama', N'United States', N'33.8', N'-87.28', N'1')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'District of Columbia', N'United States', N'38.9
', N'-77.04
', N'10')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Sindh', N'Pakistan', N'25.8943', N'68.5247', N'100')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Balochistan', N'Pakistan', N'28.4907', N'65.0958', N'101')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Khyber Pakhtunkhwa', N'Pakistan', N'34.9526', N'72.3311', N'102')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Florida', N'United States', N'28.05
', N'-82.36
', N'11')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Georgia', N'United States', N'33.84
', N'-84.38
', N'12')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Hawaii', N'United States', N'21.3
', N'-157.79
', N'13')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Idaho', N'United States', N'48.39
', N'-116.89
', N'14')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Illinois', N'United States', N'42.05
', N'-88.05
', N'15')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Indiana', N'United States', N'39.79
', N'-86.17
', N'16')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Iowa', N'United States', N'43.03
', N'-96.09
', N'17')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Kansas', N'United States', N'37.69
', N'-97.34
', N'18')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Kentucky', N'United States', N'39.02
', N'-84.56
', N'19')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Alaska', N'United States', N'61.52', N'-149.57', N'2')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Louisiana', N'United States', N'29.91
', N'-90.05
', N'20')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Maine', N'United States', N'44.08
', N'-70.17
', N'21')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Maryland', N'United States', N'39.1
', N'-76.88
', N'22')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Massachusetts', N'United States', N'42.56
', N'-72.18
', N'23')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Michigan', N'United States', N'43.93
', N'-86.26
', N'24')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Minnesota', N'United States', N'44.98
', N'-93.27
', N'25')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Mississippi', N'United States', N'32.37
', N'-90.11
', N'26')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Missouri', N'United States', N'38.25
', N'-94.31
', N'27')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Montana', N'United States', N'45.77
', N'-110.93
', N'28')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Nebraska', N'United States', N'41.11
', N'-95.93
', N'29')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Arizona', N'United States', N'33.46', N'-111.99', N'3')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Nevada', N'United States', N'36.17
', N'-115.28
', N'30')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'New Hampshire', N'United States', N'42.87
', N'-71.39
', N'31')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'New Jersey', N'United States', N'39.82
', N'-75.13
', N'32')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'New Mexico', N'United States', N'35.78
', N'-105.87
', N'33')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'New York', N'United States', N'40.76
', N'-73.97
', N'34')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'North Carolina', N'United States', N'35.75
', N'-78.72
', N'35')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'North Dakota', N'United States', N'46.96
', N'-97.68
', N'36')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Ohio', N'United States', N'39.11
', N'-84.5
', N'37')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Oklahoma', N'United States', N'34.66
', N'-98.48
', N'38')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Oregon', N'United States', N'45.44
', N'-122.97
', N'39')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Arkansas', N'United States', N'36.19', N'-94.24', N'4')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Pennsylvania', N'United States', N'40.45
', N'-79.99
', N'40')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Rhode Island', N'United States', N'41.82
', N'-71.41
', N'41')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'South Carolina', N'United States', N'33.92
', N'-80.34
', N'42')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'South Dakota', N'United States', N'43.72
', N'-98.03
', N'43')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Tennessee', N'United States', N'35.04
', N'-89.93
', N'44')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Texas', N'United States', N'30.27
', N'-97.74
', N'45')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Utah', N'United States', N'40.76
', N'-111.89
', N'46')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Vermont', N'United States', N'44.49
', N'-73.23
', N'47')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Virginia', N'United States', N'37.13
', N'-76.45
', N'48')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Washington', N'United States', N'47.09
', N'-122.65
', N'49')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Armed Forces US', N'United States', N'31.53', N'-110.36
', N'5')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'West Virginia', N'United States', N'39.46
', N'-77.95
', N'50')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Wisconsin', N'United States', N'44.63
', N'-90.2
', N'51')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Wyoming', N'United States', N'44.78
', N'-107.55
', N'52')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Andhra Pradesh', N'India', N'15.9129', N'79.7400', N'53')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Arunachal Pradesh', N'India', N'94.7278', N'28.2180', N'54')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Asom', N'India', N'24.3', N'	89.5', N'56')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Bihar', N'India', N'24.20', N'83.19', N'57')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Chhattisgarh', N'India', N'17.46', N'	80.15', N'58')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Goa', N'India', N'14.53', N'	73.40', N'59')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'California', N'United States', N'37.42', N'-122.06
', N'6')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Haryana', N'India', N'27.39', N'74.28', N'61')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Himachal Pradesh', N'India', N'30.22', N'75.45', N'62')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Jammu & Kashmir', N'India', N'32.74', N'72.31', N'63')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Jharkhand', N'India', N'21.95', N'83.35', N'64')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Karnataka', N'India', N'11.30 ', N'78.30', N'65')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Kerala', N'India', N'8.17', N'74.6', N'66')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Madhya Pradesh', N'India', N'21.15', N'74.03', N'67')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Maharashtra', N'India', N'15.55', N'72.5', N'68')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Manipur', N'India', N'23.83', N'93.03', N'69')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Colorado', N'United States', N'39.74
', N'-104.98
', N'7')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Meghalaya', N'India', N'20.1', N'85.49', N'70')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Mizoram', N'India', N'21.58', N'	92.29', N'71')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Nagaland', N'India', N'25.6', N'	93.20', N'72')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Odisha (Orissa)', N'India', N'17.49', N'	81.27', N'73')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Punjab', N'India', N'29.30', N'73.55', N'74')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Rajasthan', N'India', N'23.3', N'69.3', N'75')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Sikkim', N'India', N'27.04', N'88.00', N'76')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Tamil Nadu', N'India', N'20.25', N'	85.35', N'77')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Tripura', N'India', N'22.56', N'91.09', N'78')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Uttarakhand', N'India', N'28.43', N'77.34', N'79')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Connecticut', N'United States', N'41.14
', N'-73.26
', N'8')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Uttar Pradesh', N'India', N'23.52', N'	77.3', N'80')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'West Bangal', N'India', N'22.5', N'85.8', N'82')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Alberta', N'Canada', N'53.01669802', N'-112.8166386', N'83')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'British Columbia', N'Canada', N'49.09996035', N'-116.516697', N'84')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Manitoba', N'Canada', N'50.15002545', N'-96.88332178', N'87')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'New Brunswick', N'Canada', N'45.26704185', N'-66.07667505', N'88')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Newfoundland And Labrador', N'Canada', N'49.17440025', N'-57.42691878', N'89')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Delaware', N'United States', N'39.62
', N'-75.7
', N'9')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Northwest Territories', N'Canada', N'62.40005292', N'-110.7333291', N'90')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Nova Scotia', N'Canada', N'45.58327578', N'-62.63331934', N'91')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Nunavut', N'Canada', N'68.76746684', N'	-81.23608303', N'92')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Ontario', N'Canada', N'44.56664532', N'-80.84998519', N'93')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Prince Edward Island', N'Canada', N'46.24928164', N'-63.13132512', N'95')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Quebec', N'Canada', N'49.82257774', N'-64.34799504', N'96')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Saskatchewan', N'Canada', N'50.93331097', N'-102.7999891', N'97')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Yukon', N'Canada', N'61.35037539', N'-139.0000017', N'98')
INSERT [dbo].[lkpAllStates] ([StateName], [CountryCode], [Latitude], [Longitude], [StateId]) VALUES (N'Punjab', N'Pakistan', N'31.1471', N'75.3412', N'99')
SET IDENTITY_INSERT [dbo].[lkpBusinessAnalyst] ON 

INSERT [dbo].[lkpBusinessAnalyst] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'abc', N'test', NULL, NULL)
SET IDENTITY_INSERT [dbo].[lkpBusinessAnalyst] OFF
SET IDENTITY_INSERT [dbo].[lkpCity] ON 

INSERT [dbo].[lkpCity] ([CityId], [CityName], [StateId], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (1, N'Lahore', 43, N'31.549722', N'74.343611', NULL, 1, CAST(0x0000ABF001116B45 AS DateTime), CAST(0x0000ABF001116B45 AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[lkpCity] OFF
SET IDENTITY_INSERT [dbo].[lkpClusterType] ON 

INSERT [dbo].[lkpClusterType] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'clustertype', N'des', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpClusterType] OFF
SET IDENTITY_INSERT [dbo].[lkpCountry] ON 

INSERT [dbo].[lkpCountry] ([CountryId], [CountryName], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (50, N'Canada', N'56.130366', N'-106.346771', 4, 1, CAST(0x0000ABAE01241545 AS DateTime), CAST(0x0000ABAE01241545 AS DateTime), 0, 0)
INSERT [dbo].[lkpCountry] ([CountryId], [CountryName], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (51, N'United States', N'37.09024', N'-95.712891', 4, 1, CAST(0x0000ABAE01243480 AS DateTime), CAST(0x0000ABAE01243480 AS DateTime), 0, 0)
INSERT [dbo].[lkpCountry] ([CountryId], [CountryName], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (52, N'Pakistan', N'30.375321', N'69.345116', 4, 1, CAST(0x0000ABF001113619 AS DateTime), CAST(0x0000ABF001113619 AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[lkpCountry] OFF
SET IDENTITY_INSERT [dbo].[lkpDataCenter] ON 

INSERT [dbo].[lkpDataCenter] ([DataCenterId], [DataCenterName], [CityId], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (1, N'dh-1', 1, NULL, 1, CAST(0x0000ABF001118675 AS DateTime), CAST(0x0000ABF001118675 AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[lkpDataCenter] OFF
SET IDENTITY_INSERT [dbo].[lkpDBA] ON 

INSERT [dbo].[lkpDBA] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'test', N'testing', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
INSERT [dbo].[lkpDBA] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (2, N'checked', N'testing', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpDBA] OFF
SET IDENTITY_INSERT [dbo].[lkpDepartment] ON 

INSERT [dbo].[lkpDepartment] ([DepartmentId], [DepartmentName], [DataCenterId], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (1, N'qa-1', 1, NULL, 1, CAST(0x0000ABF00111A768 AS DateTime), CAST(0x0000ABF00111A768 AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[lkpDepartment] OFF
SET IDENTITY_INSERT [dbo].[lkpFibreBackup] ON 

INSERT [dbo].[lkpFibreBackup] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'check', N'test', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpFibreBackup] OFF
SET IDENTITY_INSERT [dbo].[lkpFibreSwitchName] ON 

INSERT [dbo].[lkpFibreSwitchName] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'test', N'switch', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpFibreSwitchName] OFF
SET IDENTITY_INSERT [dbo].[lkpFibreSwitchPort] ON 

INSERT [dbo].[lkpFibreSwitchPort] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'testing', N'testing', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpFibreSwitchPort] OFF
SET IDENTITY_INSERT [dbo].[lkpInstaller] ON 

INSERT [dbo].[lkpInstaller] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'abc', N'desc', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpInstaller] OFF
SET IDENTITY_INSERT [dbo].[lkpITGroup] ON 

INSERT [dbo].[lkpITGroup] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'ITGroup', N'test', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpITGroup] OFF
SET IDENTITY_INSERT [dbo].[lkpLeadDev] ON 

INSERT [dbo].[lkpLeadDev] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'abc', N'try', NULL, NULL)
SET IDENTITY_INSERT [dbo].[lkpLeadDev] OFF
SET IDENTITY_INSERT [dbo].[lkpLocation] ON 

INSERT [dbo].[lkpLocation] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'test', N'db', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpLocation] OFF
SET IDENTITY_INSERT [dbo].[lkpNetworkType] ON 

INSERT [dbo].[lkpNetworkType] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'networkdb', N'test', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpNetworkType] OFF
SET IDENTITY_INSERT [dbo].[lkpProgrammingLanguage] ON 

INSERT [dbo].[lkpProgrammingLanguage] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'aaaaaa', N'testing', NULL, NULL)
SET IDENTITY_INSERT [dbo].[lkpProgrammingLanguage] OFF
SET IDENTITY_INSERT [dbo].[lkpSAN] ON 

INSERT [dbo].[lkpSAN] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'sandb', N'test', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpSAN] OFF
SET IDENTITY_INSERT [dbo].[lkpSANSwitchName] ON 

INSERT [dbo].[lkpSANSwitchName] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'sanswitchdb', N'testing', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpSANSwitchName] OFF
SET IDENTITY_INSERT [dbo].[lkpSANSwitchPort] ON 

INSERT [dbo].[lkpSANSwitchPort] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'switchportdb', N'test', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpSANSwitchPort] OFF
SET IDENTITY_INSERT [dbo].[lkpServerType] ON 

INSERT [dbo].[lkpServerType] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'Serverdb', N'testing', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpServerType] OFF
SET IDENTITY_INSERT [dbo].[lkpState] ON 

INSERT [dbo].[lkpState] ([StateId], [StateName], [CountryId], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (42, N'Newfoundland And Labrador', 50, N'49.17440025', N'-57.42691878', NULL, 1, CAST(0x0000ABAE012509E5 AS DateTime), CAST(0x0000ABAE012509E5 AS DateTime), 0, 0)
INSERT [dbo].[lkpState] ([StateId], [StateName], [CountryId], [Latitude], [Longitude], [CompanyId], [Active], [CreatedAt], [ModifiedAt], [CreatedBy], [ModifiedBy]) VALUES (43, N'Punjab', 52, N'29.30', N'73.55', NULL, 1, CAST(0x0000ABF00111522E AS DateTime), CAST(0x0000ABF00111522E AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[lkpState] OFF
SET IDENTITY_INSERT [dbo].[lkpVHost] ON 

INSERT [dbo].[lkpVHost] ([LookupID], [CodeValue], [Description], [EffectiveDate], [InvalidDate]) VALUES (1, N'VHost', N'desc', CAST(0x0000AA85014DB829 AS DateTime), CAST(0x0000AA85014DB829 AS DateTime))
SET IDENTITY_INSERT [dbo].[lkpVHost] OFF
SET IDENTITY_INSERT [dbo].[Server] ON 

INSERT [dbo].[Server] ([ServerID], [Name], [LocationID], [IPAddress], [AdminEngineerID], [OS], [ProcessorNumber], [CPUSpeed], [ServerMemory], [Comment], [VHostName], [VirtualHostType], [BackupDescription], [WebServerTypeID], [ServerTypeID], [AntiVirusTypeID], [RebootSchedule], [ControllerNumber], [DiskCapacity], [NetworkTypeID], [ITGroupID], [GroupDescription], [CabinetNo], [ChasisNo], [ModelNo], [BladeNo], [Generation], [SerialNo], [ILODNSName], [ILOIPAddress], [IPAddress2], [IPAddress3], [BackUpPath], [ILOLicense], [LastUpdatedBy], [LastUpdated], [NIC1CableNo], [NIC1BunbleNo], [IPAddress4], [SAN], [SANSwitchName], [SANSwitchPort], [FibreBackup], [FibreSwitchName], [FibreSwitchPort], [ClusterType], [ClusterName], [ClusterIP1], [ClusterIP2], [ManufacturerNumber], [Manufacturer], [WarrantyExpiration], [NIC1Bundle], [NIC2Bundle], [NIC3Bundle], [NIC4Bundle], [NIC1Cable], [NIC2Cable], [NIC3Cable], [NIC4Cable], [ClusterSAN], [LUNNumber], [SMTP], [Description], [Location], [Network], [iLO_Connection], [ILO_Password], [IsBackup], [IsVirtualize], [Extend_Warranty], [NIC1Interface], [NIC2Interface], [NIC3Interface], [NIC4Interface], [NIC1Subnet], [NIC2Subnet], [NIC3Subnet], [NIC4Subnet], [NIC1SwitchPortNum], [NIC2SwitchPortNum], [NIC3SwitchPortNum], [NIC4SwitchPortNum], [NIC1VLAN], [NIC2VLAN], [NIC3VLAN], [NIC4VLAN], [NIC1SwitchName], [NIC2SwitchName], [NIC3SwitchName], [NIC4SwitchName], [CPUType], [DNSServer1], [DNSServer2], [PhysicalDiskSize], [RaidType], [PhysicalDisks], [Partition1DriveName], [Partition2DriveName], [Partition3DriveName], [Partition4DriveName], [Partition5DriveName], [Partition6DriveName], [Partition7DriveName], [Partition8DriveName], [Partition9DriveName], [Partition10DriveName], [Partition1Size], [Partition2Size], [Partition3Size], [Partition4Size], [Partition5Size], [Partition6Size], [Partition7Size], [Partition8Size], [Partition9Size], [Partition10Size], [VPartition1DriveName], [VPartition2DriveName], [VPartition3DriveName], [VPartition4DriveName], [VPartition5DriveName], [VPartition6DriveName], [VPartition7DriveName], [VPartition8DriveName], [VPartition9DriveName], [VPartition10DriveName], [VPartition1Size], [VPartition2Size], [VPartition3Size], [VPartition4Size], [VPartition5Size], [VPartition6Size], [VPartition7Size], [VPartition8Size], [VPartition9Size], [VPartition10Size], [Ownership], [NumPartitions], [VNumPartitions], [ILOPassword], [ServerUseID]) VALUES (5023, N'masoom', 1, N'ipadd', 2, 2, 3, N'speed', N'ok', N'comment', N'hostname', 2, N'backup', 2, 1, 3, N'reboot', 5, N'disk', 1, 1, N'group', N'cabinet', N'chasis', N'model', N'blade', N'gene', N'serial', N'ilodns', N'iloip', N'ipadd', N'ipadd', N'backup', N'license', NULL, CAST(0x0000ABAB0106CCE6 AS DateTime), N'cable', N'bunble', N'ipadd', 1, 1, 1, 1, 1, 1, 1, N'clustername', N'clusterip2', NULL, N'manu', NULL, CAST(0x0000ABAB0106CCE6 AS DateTime), N'bundle', N' bundle', N'nic3', N'nic4', N'nic1', N'cable', N'cable', N'cable', 2, N'number', 1, N'desc', N'location', N'network', N'takhayultech@gmail.com', N'abc', NULL, 1, 0, N'inter', N'inter', N'inter', N'inte', N'sub', N'sub', N'sub', N'sub', N'port', N'port', N'port', N'port', 9, 8, 7, 6, 5, 4, 3, 2, N'cpu', N'server', N'server', N'physical', 9, 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 9, NULL, NULL, N'abc', 2)
INSERT [dbo].[Server] ([ServerID], [Name], [LocationID], [IPAddress], [AdminEngineerID], [OS], [ProcessorNumber], [CPUSpeed], [ServerMemory], [Comment], [VHostName], [VirtualHostType], [BackupDescription], [WebServerTypeID], [ServerTypeID], [AntiVirusTypeID], [RebootSchedule], [ControllerNumber], [DiskCapacity], [NetworkTypeID], [ITGroupID], [GroupDescription], [CabinetNo], [ChasisNo], [ModelNo], [BladeNo], [Generation], [SerialNo], [ILODNSName], [ILOIPAddress], [IPAddress2], [IPAddress3], [BackUpPath], [ILOLicense], [LastUpdatedBy], [LastUpdated], [NIC1CableNo], [NIC1BunbleNo], [IPAddress4], [SAN], [SANSwitchName], [SANSwitchPort], [FibreBackup], [FibreSwitchName], [FibreSwitchPort], [ClusterType], [ClusterName], [ClusterIP1], [ClusterIP2], [ManufacturerNumber], [Manufacturer], [WarrantyExpiration], [NIC1Bundle], [NIC2Bundle], [NIC3Bundle], [NIC4Bundle], [NIC1Cable], [NIC2Cable], [NIC3Cable], [NIC4Cable], [ClusterSAN], [LUNNumber], [SMTP], [Description], [Location], [Network], [iLO_Connection], [ILO_Password], [IsBackup], [IsVirtualize], [Extend_Warranty], [NIC1Interface], [NIC2Interface], [NIC3Interface], [NIC4Interface], [NIC1Subnet], [NIC2Subnet], [NIC3Subnet], [NIC4Subnet], [NIC1SwitchPortNum], [NIC2SwitchPortNum], [NIC3SwitchPortNum], [NIC4SwitchPortNum], [NIC1VLAN], [NIC2VLAN], [NIC3VLAN], [NIC4VLAN], [NIC1SwitchName], [NIC2SwitchName], [NIC3SwitchName], [NIC4SwitchName], [CPUType], [DNSServer1], [DNSServer2], [PhysicalDiskSize], [RaidType], [PhysicalDisks], [Partition1DriveName], [Partition2DriveName], [Partition3DriveName], [Partition4DriveName], [Partition5DriveName], [Partition6DriveName], [Partition7DriveName], [Partition8DriveName], [Partition9DriveName], [Partition10DriveName], [Partition1Size], [Partition2Size], [Partition3Size], [Partition4Size], [Partition5Size], [Partition6Size], [Partition7Size], [Partition8Size], [Partition9Size], [Partition10Size], [VPartition1DriveName], [VPartition2DriveName], [VPartition3DriveName], [VPartition4DriveName], [VPartition5DriveName], [VPartition6DriveName], [VPartition7DriveName], [VPartition8DriveName], [VPartition9DriveName], [VPartition10DriveName], [VPartition1Size], [VPartition2Size], [VPartition3Size], [VPartition4Size], [VPartition5Size], [VPartition6Size], [VPartition7Size], [VPartition8Size], [VPartition9Size], [VPartition10Size], [Ownership], [NumPartitions], [VNumPartitions], [ILOPassword], [ServerUseID]) VALUES (5024, N'name', 1, N'ipadd', 2, 2, 0, N'speed', N'memory', N'comment', N'Sloth Bear', 0, N'', 2, 1, 2, N'', 0, N'', 0, 1, N'', NULL, NULL, NULL, NULL, NULL, N'', N'', N'', N'', N'', N'', N'', NULL, CAST(0x0000ABF001203DDE AS DateTime), NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, CAST(0x0000ABF001203DDE AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, 2)
INSERT [dbo].[Server] ([ServerID], [Name], [LocationID], [IPAddress], [AdminEngineerID], [OS], [ProcessorNumber], [CPUSpeed], [ServerMemory], [Comment], [VHostName], [VirtualHostType], [BackupDescription], [WebServerTypeID], [ServerTypeID], [AntiVirusTypeID], [RebootSchedule], [ControllerNumber], [DiskCapacity], [NetworkTypeID], [ITGroupID], [GroupDescription], [CabinetNo], [ChasisNo], [ModelNo], [BladeNo], [Generation], [SerialNo], [ILODNSName], [ILOIPAddress], [IPAddress2], [IPAddress3], [BackUpPath], [ILOLicense], [LastUpdatedBy], [LastUpdated], [NIC1CableNo], [NIC1BunbleNo], [IPAddress4], [SAN], [SANSwitchName], [SANSwitchPort], [FibreBackup], [FibreSwitchName], [FibreSwitchPort], [ClusterType], [ClusterName], [ClusterIP1], [ClusterIP2], [ManufacturerNumber], [Manufacturer], [WarrantyExpiration], [NIC1Bundle], [NIC2Bundle], [NIC3Bundle], [NIC4Bundle], [NIC1Cable], [NIC2Cable], [NIC3Cable], [NIC4Cable], [ClusterSAN], [LUNNumber], [SMTP], [Description], [Location], [Network], [iLO_Connection], [ILO_Password], [IsBackup], [IsVirtualize], [Extend_Warranty], [NIC1Interface], [NIC2Interface], [NIC3Interface], [NIC4Interface], [NIC1Subnet], [NIC2Subnet], [NIC3Subnet], [NIC4Subnet], [NIC1SwitchPortNum], [NIC2SwitchPortNum], [NIC3SwitchPortNum], [NIC4SwitchPortNum], [NIC1VLAN], [NIC2VLAN], [NIC3VLAN], [NIC4VLAN], [NIC1SwitchName], [NIC2SwitchName], [NIC3SwitchName], [NIC4SwitchName], [CPUType], [DNSServer1], [DNSServer2], [PhysicalDiskSize], [RaidType], [PhysicalDisks], [Partition1DriveName], [Partition2DriveName], [Partition3DriveName], [Partition4DriveName], [Partition5DriveName], [Partition6DriveName], [Partition7DriveName], [Partition8DriveName], [Partition9DriveName], [Partition10DriveName], [Partition1Size], [Partition2Size], [Partition3Size], [Partition4Size], [Partition5Size], [Partition6Size], [Partition7Size], [Partition8Size], [Partition9Size], [Partition10Size], [VPartition1DriveName], [VPartition2DriveName], [VPartition3DriveName], [VPartition4DriveName], [VPartition5DriveName], [VPartition6DriveName], [VPartition7DriveName], [VPartition8DriveName], [VPartition9DriveName], [VPartition10DriveName], [VPartition1Size], [VPartition2Size], [VPartition3Size], [VPartition4Size], [VPartition5Size], [VPartition6Size], [VPartition7Size], [VPartition8Size], [VPartition9Size], [VPartition10Size], [Ownership], [NumPartitions], [VNumPartitions], [ILOPassword], [ServerUseID]) VALUES (5025, N'abcxyzjjjjj', 1, N'ip', 2, 2, 0, N'speed', N'memory', N'comment', N'1', 0, N'backup', 2, 1, 2, N'reboot', 0, N'disk', 0, 1, N'group', NULL, NULL, NULL, NULL, NULL, N'serial', N'ilodns', N'iloip', N'ipadd', N'ipadd', N'back', N'abc', NULL, CAST(0x0000ABF0014466AB AS DateTime), NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, CAST(0x0000ABF0014466AB AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, 2)
SET IDENTITY_INSERT [dbo].[Server] OFF
SET IDENTITY_INSERT [dbo].[ServerDatabase] ON 

INSERT [dbo].[ServerDatabase] ([ServerDatabaseID], [ServerID], [DatabaseID]) VALUES (3007, 5023, 3012)
INSERT [dbo].[ServerDatabase] ([ServerDatabaseID], [ServerID], [DatabaseID]) VALUES (3008, 5024, 3011)
INSERT [dbo].[ServerDatabase] ([ServerDatabaseID], [ServerID], [DatabaseID]) VALUES (3009, 5025, 3011)
SET IDENTITY_INSERT [dbo].[ServerDatabase] OFF
SET IDENTITY_INSERT [dbo].[ServerDocument] ON 

INSERT [dbo].[ServerDocument] ([ServerDocumentID], [ServerID], [DocumentID]) VALUES (3007, 5023, 5)
INSERT [dbo].[ServerDocument] ([ServerDocumentID], [ServerID], [DocumentID]) VALUES (3008, 5024, 5)
INSERT [dbo].[ServerDocument] ([ServerDocumentID], [ServerID], [DocumentID]) VALUES (3009, 5025, 5)
SET IDENTITY_INSERT [dbo].[ServerDocument] OFF
SET IDENTITY_INSERT [dbo].[UserCountry] ON 

INSERT [dbo].[UserCountry] ([UserCountryId], [CountryId], [UserId]) VALUES (1, 42, N'd7a06c53-7cfc-4809-8193-957fbb6463ad')
SET IDENTITY_INSERT [dbo].[UserCountry] OFF
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Application]    Script Date: 7/7/2020 3:33:55 PM ******/
ALTER TABLE [dbo].[Application] ADD  CONSTRAINT [IX_Application] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_AspNetRoleClaims_RoleId]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [IX_AspNetRoleClaims_RoleId] ON [dbo].[AspNetRoleClaims]
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [RoleNameIndex]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [RoleNameIndex] ON [dbo].[AspNetRoles]
(
	[NormalizedName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_AspNetUserClaims_UserId]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [IX_AspNetUserClaims_UserId] ON [dbo].[AspNetUserClaims]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_AspNetUserLogins_UserId]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [IX_AspNetUserLogins_UserId] ON [dbo].[AspNetUserLogins]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_AspNetUserRoles_RoleId]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [IX_AspNetUserRoles_RoleId] ON [dbo].[AspNetUserRoles]
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_AspNetUserRoles_UserId]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [IX_AspNetUserRoles_UserId] ON [dbo].[AspNetUserRoles]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [EmailIndex]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE NONCLUSTERED INDEX [EmailIndex] ON [dbo].[AspNetUsers]
(
	[NormalizedEmail] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [UserNameIndex]    Script Date: 7/7/2020 3:33:55 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex] ON [dbo].[AspNetUsers]
(
	[NormalizedUserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_lkpCountry]    Script Date: 7/7/2020 3:33:55 PM ******/
ALTER TABLE [dbo].[lkpCountry] ADD  CONSTRAINT [IX_lkpCountry] UNIQUE NONCLUSTERED 
(
	[CountryName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ApplicationADGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationADGroup_ADGroup] FOREIGN KEY([ADGroupID])
REFERENCES [dbo].[ADGroup] ([ADGroupID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationADGroup] CHECK CONSTRAINT [FK_ApplicationADGroup_ADGroup]
GO
ALTER TABLE [dbo].[ApplicationADGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationADGroup_Application] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ApplicationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationADGroup] CHECK CONSTRAINT [FK_ApplicationADGroup_Application]
GO
ALTER TABLE [dbo].[ApplicationContact]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationContact_Application] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ApplicationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationContact] CHECK CONSTRAINT [FK_ApplicationContact_Application]
GO
ALTER TABLE [dbo].[ApplicationContact]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationContact_Contact] FOREIGN KEY([ContactID])
REFERENCES [dbo].[Contact] ([ContactID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationContact] CHECK CONSTRAINT [FK_ApplicationContact_Contact]
GO
ALTER TABLE [dbo].[ApplicationDatabase]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationDatabase_Application] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ApplicationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationDatabase] CHECK CONSTRAINT [FK_ApplicationDatabase_Application]
GO
ALTER TABLE [dbo].[ApplicationDatabase]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationDatabase_Database] FOREIGN KEY([DatabaseID])
REFERENCES [dbo].[Databases] ([DatabaseID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationDatabase] CHECK CONSTRAINT [FK_ApplicationDatabase_Database]
GO
ALTER TABLE [dbo].[ApplicationDocument]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationDocument_Application] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ApplicationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationDocument] CHECK CONSTRAINT [FK_ApplicationDocument_Application]
GO
ALTER TABLE [dbo].[ApplicationDocument]  WITH NOCHECK ADD  CONSTRAINT [FK_ApplicationDocument_Document] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[Document] ([DocumentID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApplicationDocument] CHECK CONSTRAINT [FK_ApplicationDocument_Document]
GO
ALTER TABLE [dbo].[AspNetRoleClaims]  WITH CHECK ADD  CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[AspNetRoles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetRoleClaims] CHECK CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId]
GO
ALTER TABLE [dbo].[AspNetUserClaims]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserClaims] CHECK CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId]
GO
ALTER TABLE [dbo].[AspNetUserLogins]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserLogins] CHECK CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId]
GO
ALTER TABLE [dbo].[AspNetUserRoles]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[AspNetRoles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserRoles] CHECK CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId]
GO
ALTER TABLE [dbo].[AspNetUserRoles]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserRoles] CHECK CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId]
GO
ALTER TABLE [dbo].[Authorization_AllowedCities]  WITH CHECK ADD  CONSTRAINT [FK_Authorization_AllowedCities_AspNetUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Authorization_AllowedCities] CHECK CONSTRAINT [FK_Authorization_AllowedCities_AspNetUsers]
GO
ALTER TABLE [dbo].[Authorization_AllowedCountries]  WITH CHECK ADD  CONSTRAINT [FK_Authorization_AllowedCountries_AspNetUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Authorization_AllowedCountries] CHECK CONSTRAINT [FK_Authorization_AllowedCountries_AspNetUsers]
GO
ALTER TABLE [dbo].[Authorization_AllowedDatacenters]  WITH CHECK ADD  CONSTRAINT [FK_Authorization_AllowedDatacenters_AspNetUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Authorization_AllowedDatacenters] CHECK CONSTRAINT [FK_Authorization_AllowedDatacenters_AspNetUsers]
GO
ALTER TABLE [dbo].[Authorization_AllowedDepartments]  WITH CHECK ADD  CONSTRAINT [FK_Authorization_AllowedDepartments_AspNetUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Authorization_AllowedDepartments] CHECK CONSTRAINT [FK_Authorization_AllowedDepartments_AspNetUsers]
GO
ALTER TABLE [dbo].[Authorization_AllowedStates]  WITH CHECK ADD  CONSTRAINT [FK_Authorization_AllowedStates_AspNetUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Authorization_AllowedStates] CHECK CONSTRAINT [FK_Authorization_AllowedStates_AspNetUsers]
GO
ALTER TABLE [dbo].[CommunityADGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_CommunityADGroup_ADGroup] FOREIGN KEY([ADGroupID])
REFERENCES [dbo].[ADGroup] ([ADGroupID])
GO
ALTER TABLE [dbo].[CommunityADGroup] CHECK CONSTRAINT [FK_CommunityADGroup_ADGroup]
GO
ALTER TABLE [dbo].[CommunityADGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_CommunityADGroup_Community] FOREIGN KEY([CommunityID])
REFERENCES [dbo].[Community] ([CommunityID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommunityADGroup] CHECK CONSTRAINT [FK_CommunityADGroup_Community]
GO
ALTER TABLE [dbo].[CommunityDocument]  WITH NOCHECK ADD  CONSTRAINT [FK_CommunityDocument_Community] FOREIGN KEY([CommunityID])
REFERENCES [dbo].[Community] ([CommunityID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommunityDocument] CHECK CONSTRAINT [FK_CommunityDocument_Community]
GO
ALTER TABLE [dbo].[CommunityDocument]  WITH CHECK ADD  CONSTRAINT [FK_CommunityDocument_Document] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[Document] ([DocumentID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommunityDocument] CHECK CONSTRAINT [FK_CommunityDocument_Document]
GO
ALTER TABLE [dbo].[DatabaseDocument]  WITH NOCHECK ADD  CONSTRAINT [FK_DatabaseDocument_Database] FOREIGN KEY([DatabaseID])
REFERENCES [dbo].[Databases] ([DatabaseID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DatabaseDocument] CHECK CONSTRAINT [FK_DatabaseDocument_Database]
GO
ALTER TABLE [dbo].[DatabaseDocument]  WITH NOCHECK ADD  CONSTRAINT [FK_DatabaseDocument_Document] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[Document] ([DocumentID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DatabaseDocument] CHECK CONSTRAINT [FK_DatabaseDocument_Document]
GO
ALTER TABLE [dbo].[Framework_Server_Location]  WITH CHECK ADD  CONSTRAINT [FK_Framework_Server_Location_Server] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Server] ([ServerID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Framework_Server_Location] CHECK CONSTRAINT [FK_Framework_Server_Location_Server]
GO
ALTER TABLE [dbo].[Installation]  WITH NOCHECK ADD  CONSTRAINT [FK_Installation_Application] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ApplicationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Installation] CHECK CONSTRAINT [FK_Installation_Application]
GO
ALTER TABLE [dbo].[lkpApplication]  WITH CHECK ADD  CONSTRAINT [FK_lkpApplication_lkpDepartment] FOREIGN KEY([DepartmentId])
REFERENCES [dbo].[lkpDepartment] ([DepartmentId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lkpApplication] CHECK CONSTRAINT [FK_lkpApplication_lkpDepartment]
GO
ALTER TABLE [dbo].[lkpCity]  WITH CHECK ADD  CONSTRAINT [FK_lkpCity_lkpState] FOREIGN KEY([StateId])
REFERENCES [dbo].[lkpState] ([StateId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lkpCity] CHECK CONSTRAINT [FK_lkpCity_lkpState]
GO
ALTER TABLE [dbo].[lkpDataCenter]  WITH CHECK ADD  CONSTRAINT [FK_lkpDataCenter_lkpCity] FOREIGN KEY([CityId])
REFERENCES [dbo].[lkpCity] ([CityId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lkpDataCenter] CHECK CONSTRAINT [FK_lkpDataCenter_lkpCity]
GO
ALTER TABLE [dbo].[lkpDepartment]  WITH CHECK ADD  CONSTRAINT [FK_lkpDepartment_lkpDataCenter] FOREIGN KEY([DataCenterId])
REFERENCES [dbo].[lkpDataCenter] ([DataCenterId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lkpDepartment] CHECK CONSTRAINT [FK_lkpDepartment_lkpDataCenter]
GO
ALTER TABLE [dbo].[lkpState]  WITH CHECK ADD  CONSTRAINT [FK_lkpState_lkpCountry] FOREIGN KEY([CountryId])
REFERENCES [dbo].[lkpCountry] ([CountryId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lkpState] CHECK CONSTRAINT [FK_lkpState_lkpCountry]
GO
ALTER TABLE [dbo].[OutsideDeveloper]  WITH NOCHECK ADD  CONSTRAINT [FK_OutsideDeveloper_Contact] FOREIGN KEY([ContactID])
REFERENCES [dbo].[Contact] ([ContactID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OutsideDeveloper] CHECK CONSTRAINT [FK_OutsideDeveloper_Contact]
GO
ALTER TABLE [dbo].[ServerDatabase]  WITH CHECK ADD  CONSTRAINT [FK_ServerDatabase_Database] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Server] ([ServerID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ServerDatabase] CHECK CONSTRAINT [FK_ServerDatabase_Database]
GO
ALTER TABLE [dbo].[ServerDocument]  WITH CHECK ADD  CONSTRAINT [FK_ServerDocument_Document] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Server] ([ServerID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ServerDocument] CHECK CONSTRAINT [FK_ServerDocument_Document]
GO
USE [master]
GO
ALTER DATABASE [dMUDH] SET  READ_WRITE 
GO
