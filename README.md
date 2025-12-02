ruby-handlebars
===============

[![Build status](https://github.com/SmartBear/ruby-handlebars/actions/workflows/ci.yml/badge.svg)](https://github.com/jejacks0n/ruby-handlebars/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/gh/jejacks0n/projects/ruby-handlebars/maintainability.svg)](https://qlty.sh/gh/jejacks0n/projects/ruby-handlebars)
[![Code Coverage](https://qlty.sh/gh/jejacks0n/projects/ruby-handlebars/coverage.svg)](https://qlty.sh/gh/jejacks0n/projects/ruby-handlebars)

Pure Ruby library for [Handlebars](http://handlebarsjs.com/) template system.

The main goal of this library is to simplify the use of Ruby and Handlebars. It attempts to reduce the dependency on things like v8, and therubyracer/miniracer. If you want those complications, look at [handlebars.rb](https://github.com/cowboyd/handlebars.rb) which uses the real Handlebars library. Please note that handlebars.rb has some thread challenges that made it impossible for us to reliably use and scale.

## Installing

Add it to your Gemfile:

```shell
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
gem "ruby-handlebars", github: "jejacks0n/handlebars"
```

No need for libv8, therubyracer or any JS related tools.

## Usage

A very simple case:

```ruby
require 'ruby-handlebars'

hbs = Handlebars::Handlebars.new
hbs.compile("Hello {{name}}").call({name: 'world'})
# Gives: "Hello world", how original ...
```

You can also use partials:

```ruby
hbs.register_partial('full_name', "{{person.first_name}} {{person.last_name}}")
hbs.compile("Hello {{> full_name}}").call({person: {first_name: 'Pinkie', last_name: 'Pie'}})
# Gives: "Hello Pinkie Pie"
```

Partials support parameters:

```ruby
hbs.register_partial('full_name', "{{fname}} {{lname}}")
hbs.compile("Hello {{> full_name fname='jon' lname='doe'}}")
# Gives: "Hello jon doe"
```

You can also register inline helpers:

```ruby
hbs.register_helper('strip') { |_context, value| value.strip }
hbs.compile("Hello {{strip name}}").call({name: '                       world     '})
# Will give (again ....): "Hello world"
```

or block helpers:

```ruby
hbs.register_helper('comment') do |context, commenter, block:, **opts|
  block.fn(context).split("\n").map do |line|
    "#{commenter} #{line}"
  end.join("\n")
end

hbs.compile("{{#comment '//'}}My comment{{/comment}}").call
# Will give: "// My comment"
```

Note that in any block helper you can use an `else` block:

```ruby
hbs.register_helper('markdown') do |context, block:, else_block:, **opts|
  html = md_to_html(block.fn(context))
  html.nil? ? else_block.fn(context) : html
end

template = [
  "{{#markdown}}",
  "  {{ description }}",
  "{{else}}",
  "  Description is not valid markdown, no preview available",
  "{{/markdown}}"
].join("\n")

hbs.compile(template).call({description: my_description})
# Output will depend on the validity of the 'my_description' variable
```

## Default helpers

These default helpers are provided:

- `each`
- `if`
- `unless`
- `with`
- `lookup`

The `each` helper let you walk through a list. You can either use the basic notation and referencing the current item as `this`:

```
{{#each items}}
  {{{ this }}}
{{else}}
  No items
{{/each}}
```

or the "as |name|" notation:

```
{{#each items as |item|}}
  {{{ item }}}
{{else}}
  No items
{{/each}}
```

The `if` helper can be used to write conditionnal templates:

```
{{#if my_condition}}
  It's ok
{{else}}
  or maybe not
{{/if}}
```

The `unless` helper works the opposite way to `if`:

```
{{#unless my_condition}}
  It's not ok
{{else}}
  or maybe it is
{{/unless}}
```

The `with` helper allows navigating through the context object.

```
{{#with a.b}}
  {{ c }}
{{/with}}
```

Currently, if you call an unknown helper, it will raise an exception. You can override that by registering your own version of the ``helperMissing`` helper. Note that only the name of the missing helper will be provided.

For example:

```ruby
hbs.register_helper('helperMissing') do |context, name|
  puts "No helper found with name #{name}"
end
```

## Limitations and roadmap

This gem does not reuse the real Handlebars code (the JS one) and not everything is handled yet (but it will be someday ;) ):

 - the parser is not fully tested yet, it may complain with spaces ...
 - parsing errors are, well, not helpful at all

## Acknowledgements

This gem would simply not exist if the handlebars team was not here. Thanks a lot for this awesome templating system. Thanks a lot to @cowboyd for the [handlebars.rb](https://github.com/cowboyd/handlebars.rb) gem.

Thanks a lot to the contributors @mvz, @schuetzm and @stewartmckee for making it a way better Handlebars renderer :)
