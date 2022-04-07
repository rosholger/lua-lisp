{
    ["firstline"] = 0,
    ["lastline"] = 3,
    ["kind"] = Chunk,
    ["body"] = {
        [1] = {
            ["line"] = 1,
            ["arguments"] = {
                [1] = {
                    ["kind"] = ExpressionValue,
                    ["value"] = {
                        ["line"] = 2,
                        ["arguments"] = {
                        } ,
                        ["kind"] = CallExpression,
                        ["callee"] = {
                            ["vararg"] = false,
                            ["firstline"] = 1,
                            ["lastline"] = 2,
                            ["kind"] = FunctionExpression,
                            ["params"] = {
                            } ,
                            ["body"] = {
                                [1] = {
                                    ["tests"] = {
                                        [1] = {
                                            ["kind"] = Literal,
                                            ["value"] = false,
                                        } ,
                                    } ,
                                    ["kind"] = IfStatement,
                                    ["alternate"] = {
                                        [1] = {
                                            ["line"] = 2,
                                            ["arguments"] = {
                                                [1] = {
                                                    ["kind"] = Literal,
                                                    ["value"] = 2,
                                                } ,
                                            } ,
                                            ["kind"] = ReturnStatement,
                                        } ,
                                        ["lastline"] = 2,
                                        ["firstline"] = 2,
                                    } ,
                                    ["cons"] = {
                                        [1] = {
                                            [1] = {
                                                ["line"] = 2,
                                                ["arguments"] = {
                                                    [1] = {
                                                        ["kind"] = Literal,
                                                        ["value"] = 1,
                                                    } ,
                                                } ,
                                                ["kind"] = ReturnStatement,
                                            } ,
                                            ["lastline"] = 2,
                                            ["firstline"] = 2,
                                        } ,
                                    } ,
                                    ["line"] = 2,
                                } ,
                                ["lastline"] = 2,
                            } ,
                            ["bracketed"] = true,
                        } ,
                    } ,
                } ,
            } ,
            ["kind"] = ReturnStatement,
        } ,
    } ,
    ["chunkname"] = tests/test-2.lua,
}

{
    ["firstline"] = 1,
    ["lastline"] = 1,
    ["kind"] = Chunk,
    ["body"] = {
        [1] = {
            ["line"] = 1,
            ["arguments"] = {
                [1] = {
                    ["kind"] = ExpressionValue,
                    ["value"] = {
                        ["line"] = 1,
                        ["arguments"] = {
                        } ,
                        ["kind"] = CallExpression,
                        ["callee"] = {
                            ["vararg"] = false,
                            ["firstline"] = 1,
                            ["lastline"] = 1,
                            ["kind"] = FunctionExpression,
                            ["params"] = {
                            } ,
                            ["body"] = {
                                [1] = {
                                    ["tests"] = {
                                        [1] = {
                                            ["name"] = true,
                                            ["kind"] = Identifier,
                                        } ,
                                        [2] = {
                                            ["name"] = false,
                                            ["kind"] = Identifier,
                                        } ,
                                    } ,
                                    ["line"] = 1,
                                    ["cons"] = {
                                        [1] = {
                                            ["line"] = 2,
                                            ["arguments"] = {
                                                [1] = {
                                                    ["kind"] = Literal,
                                                    ["value"] = 1,
                                                } ,
                                            } ,
                                            ["kind"] = ReturnStatement,
                                        } ,
                                        [2] = {
                                            ["line"] = 3,
                                            ["arguments"] = {
                                                [1] = {
                                                    ["kind"] = Literal,
                                                    ["value"] = 2,
                                                } ,
                                            } ,
                                            ["kind"] = ReturnStatement,
                                        } ,
                                    } ,
                                    ["kind"] = IfStatement,
                                } ,
                            } ,
                            ["bracketed"] = true,
                        } ,
                    } ,
                } ,
            } ,
            ["kind"] = ReturnStatement,
        } ,
    } ,
    ["chunkname"] = some_chunk_name,
}