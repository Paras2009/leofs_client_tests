#!/bin/env escript
%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et

-include_lib("deps/erlcloud/include/erlcloud_aws.hrl").

-define(AWS_ACCESS_KEY, "05236").
-define(AWS_SECRET_KEY, "802562235").
-define(AWS_HOST,       "localhost").
-define(AWS_PORT,       8080).
-define(FILENAME,       "README").
-define(BUCKETNAME,     "erlang").
main(_Args) ->
    ok = code:add_paths(["ebin",
                         "deps/erlcloud/ebin",
                         "deps/jsx/ebin",
                         "deps/meck/ebin"]),
    erlcloud:start(),
    Conf = erlcloud_s3:new(?AWS_ACCESS_KEY,
                           ?AWS_SECRET_KEY,
                           ?AWS_HOST,
                           ?AWS_PORT),
    Conf2 = Conf#aws_config{s3_scheme = "http://"},
    try
        % Create a bucket
        erlcloud_s3:create_bucket(?BUCKETNAME, Conf2),
        io:format("Bucket created Successfully \n"),

        % Retrieve list of buckets
        List = erlcloud_s3:list_buckets(Conf2),
        io:format("[debug] Bucket List:~p~n", [List]),

        % PUT an object into the LeoFS
        erlcloud_s3:put_object(?BUCKETNAME, "test-key", "value", [], Conf2),
        io:format("Successfully created text file \n"),
        % PUT an file into the LeoFS
        {ok, Data} = file:read_file('../temp_data/README'),
        erlcloud_s3:put_object(?BUCKETNAME, ?FILENAME, Data, Conf2),
        io:format("File Uploaded Successfully \n"),

        % COPY an file internally into LeoFS Bucket
        erlcloud_s3:copy_object(?BUCKETNAME, ?FILENAME ++ ".copy", ?BUCKETNAME, ?FILENAME, Conf2),
        io:format("File copied successfully \n"),

        % Retrieve list of objects from the LeoFS
        Objs = erlcloud_s3:list_objects(?BUCKETNAME, Conf2),
        io:format("[debug] List Objects :~p~n", [Objs]),

        % GET an object from the LeoFS
        Obj = erlcloud_s3:get_object(?BUCKETNAME, "test-key", Conf2),
        io:format("[debug]inserted object:~p~n", [Obj]),
        % GET an file object from the LeoFS
        [{_,_},{_,_},{_,_},{_,_},{_,_},{content,Objec}] = erlcloud_s3:get_object(?BUCKETNAME, ?FILENAME, [], Conf2),
        Tmp = iolist_to_binary(Objec),
        file:write_file('README.copy', Tmp),
        io:format("File Downloaded Successfully \n"),
        % GET an object metadata from the LeoFS
        Meta = erlcloud_s3:get_object_metadata(?BUCKETNAME, "test-key", Conf2),
        io:format("[debug]metadata:~p~n", [Meta]),

        % DELETE an object from the LeoFS
        DeletedObj = erlcloud_s3:delete_object(?BUCKETNAME, "test-key", Conf2),
        io:format("[debug]File Deleted Successfully:~p~n", [DeletedObj]),
        try
            NotFoundObj = erlcloud_s3:get_object(?BUCKETNAME, "test-key", Conf2),
            io:format("[debug]not found object:~p~n", [NotFoundObj])
        catch
            error:{aws_error,{http_error,404,_,_}} ->
                io:format("[debug]404 not found object~n")
        end
    after
        % DELETE a bucket from the LeoFS
        ok = erlcloud_s3:delete_bucket(?BUCKETNAME, Conf2),
        io:format("Bucket Deleted Successfully")
    end,
    ok.
