use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ruleset starter offsets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "IGNORE" } , skip = 1 },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 4, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].offset_match)
			ngx.say(mock_rules[1].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
1
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Skip 1 offsets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "IGNORE" } , skip = 1 },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 4, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
2
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Skip 2 offsets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "SKIP" } , skip = 2 },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 4, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
3
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Skip offsets to end of ruleset
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "IGNORE" } , skip = 3 },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 4, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
nil
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: Skipping chain starter
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 3, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 4, vars = {}, actions = { disrupt = "IGNORE" } , skip = 1 },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 6, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 7, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
1
3
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: Skipping chain middle
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 3, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 4, vars = {}, actions = { disrupt = "IGNORE" } , skip = 1 },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 6, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 7, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[3].offset_match)
			ngx.say(mock_rules[3].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
1
2
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: Skipping chain end
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 3, vars = {}, actions = { disrupt = "CHAIN" }  },
				{ id = 4, vars = {}, actions = { disrupt = "IGNORE" } , skip = 1 },
				{ id = 5, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 6, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 7, vars = {}, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[4].offset_match)
			ngx.say(mock_rules[4].offset_nomatch)
		}
	}
--- request
GET /t
--- response_body
2
1
--- error_code: 200
--- no_error_log
[error]

