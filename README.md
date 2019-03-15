# Onceover::Metrics

This is an example plugin for [Onceover](https://github.com/dylanratcliffe/onceover), _The gateway drug to automated infrastructure testing with Puppet_

## Installation

Onceover detects plugins in all gems named `onceover-*`.  Your plugin is then responsible for registering itself and setting up new commands, etc.

This example plugin can be installed by adding it to your `Gemfile` or by running the following command:

```shell
$ gem install onceover-metrics
```

## Usage
Onceover provides plugins with built-in support for help and argument processing.  Here's how to run this example:

**Built-in help**

```shell
$ onceover run metrics --help
```

**Default execution**

```shell
$ onceover run metrics
```

**Option processing**

```shell
$ onceover run metrics --name Wednesday
INFO   -> Hello, Wednesday!
```

## Integration highlights
* [Onceover compatibility definition](https://github.com/declarativesystems/onceover-metrics/blob/master/onceover-metrics.gemspec#L27)
* [Library self-registration](https://github.com/declarativesystems/onceover-metrics/blob/master/lib/onceover/metrics.rb#L2)
* [Command definition](https://github.com/declarativesystems/onceover-metrics/blob/master/lib/onceover/metrics/cli.rb#L9)
* [Command self-registration](https://github.com/declarativesystems/onceover-metrics/blob/master/lib/onceover/metrics/cli.rb#L34)


## Development

Finished (for now) - hopefully this makes writing your own plugins for Onceover easier :)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/declarativesystems/onceover-metrics.
