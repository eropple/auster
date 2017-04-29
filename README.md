# Auster #
_The Best Way To Wrangle CloudFormation (at least, according to me!)_

**Auster** is a best-practices extension to the [Cfer](https://github.com/seanedwards/cfer) environment that establishes conventions for effectively working with Cfer and CloudFormation. It's developed from some of the lessons that I've learned over time building out large-scale systems for companies big and small and running into the stumbling blocks that always pop up when trying to automate a full stack deployment.

The biggest roadblock to making your deployment awesome is the impedance mismatch between tools like CloudFormation (and implicitly Cfer) and the world you're working in. CloudFormation is a declarative system: "this should exist when you're done". And that's great...until you have to start introducing stateful changes to your system! (Which, if you're doing it right, will be approximately "five seconds after you stand up an RDS server.") This is where Auster comes in, allowing you to orchestrate those stateful transitions between steps.

**Caveat emptor:** The code that became Auster has been in use for a few months, but Auster itself is very much a work in progress. I use this for stuff that pays money and I'll stand behind it, but you should make your own call.

## Give It A Try ##
Auster is installable via Rubygems (`gem install auster`), but the example repo is in the same repository, so checking it out is recommended.

```bash
$ gem install auster
$ git clone git@github.com:eropple/auster.git
$ cd auster/example-repo
```

Take a look around the repo if you'd like. Ensure that you have valid AWS credentials in your environment (`AWS_PROFILE`, etc.) and then run the following to create a pair of CloudFormation stacks. All they'll do is create S3 buckets, so you won't be charged for anything.

```bash
$ auster apply us-west-2/dev-ed1 bootstrap
$ auster apply us-west-2/dev-ed1 dependent
```

If you read through the Auster output, you'll see that it's creating S3 buckets (as you'd expect--it's still CloudFormation under the hood) and registering them as region-wide exports, prefixed with the plan ID `dev1-ed`.

Anyhoo, let's clean up.

```bash
$ auster nuke us-west-2/dev-ed1
```

If you'd like more information on writing Cfer itself, check out [chef-cfer-consul-cluster](https://github.com/seanedwards/chef-cfer-consul-cluster).

## Auster Commands ##
### Generators ###
- `auster generate repo` - Creates a Auster plan repo with sample files.
- `auster generate step ##.human-tag` - Creates a new Auster step with stub files.

### Executors ###
**Note:** In the command line interface, the step number and the tag are interchangeable. `auster apply region/env 00` and `auster apply region/env human-tag` will refer to the same step, `00.human-tag`.

- `auster json us-west-2/dev1-ed (##|human-tag)` - Uses `cfer generate` to generate the output JSON that will be applied when this step is `auster apply`'d.
- `auster apply us-west-2/dev1-ed (##|human-tag)` - Runs step 01 in region `us-west2` with configuration set `dev1-ed`. This will:
  - If `/cfg/_schema.yaml` exists, it will validate `/cfg/us-west2/dev1-ed.yaml` against it and fail if it does not validate.
  - If this is the first run of this step (there is no `dev1-ed-step01` CloudFormation stack in AWS), the scripts in `/steps/01/on-create.d` will be run in lexicographic order.
  - The scripts in `/steps/01/pre-converge.d` will be run in lexicographic order.
  - Cfer will be run against the scripts in `/steps/01/cfer` to generate and apply the desired CloudFormation template.
  - The scripts in `/steps/01/post-converge.d` will be run in lexicographic order.
- `auster destroy us-west-2/dev1-ed (##|human-tag)` - Destroys step 01 in region `us-west2` with configuration set `dev1-ed`. This will:
  - Attempt to destroy the CloudFormation stack `dev1-ed-step01`. _This is not guaranteed to succeed_, especially if this stack has exports being used by other stacks.
  - If the stack is destroyed successfully, the scripts in `/steps/01/on-destroy.d` will be run in lexicographic order.
- `auster nuke us-west-2/dev1-ed` - Destroys _all_ steps in `dev1-ed` in region `us-west2`. This will request a confirmation (and will error out if no TTY is detected); you must pass the `--force` parameter to automate this destruction.

## Auster Config Sets ##
A _config set_ is a YAML file that combines Cfer parameters and Auster directives. This file may optionally be proofed with a Kwalify YAML schema in `/config/schema.yaml` and, once loaded, the loaded parameters can be proofed via a `Cfer::Auster::ParamValidator` specified in `/config/validator.rb`.

All Auster-specific parameters are stored under the `AusterOptions` key.

- `AusterOptions`
  - `S3Path`: Specifies an S3 path at which to upload the CloudFormation stack template. (This is required once your stack definition grows over a certain size; I recommend you always use it.) For Cfer uses, this is both `--s3-path` and `--force-s3`.

## Auster Event Scripts ##
There are four events for every step at which arbitrary scripts can be run: `on-create`, `pre-converge`, `post-converge`, and  `on-destroy`. (Yes, that the lexicographic ordering of `post` comes before `pre` drives me up the wall too. Sorry.) Every script in the appropriate directory within each step will be executed (based on chmod status via `File::executable?`). Ruby scripts will be loaded in-process and run directly, while all other scripts will be invoked via `system()` (so on Unixes the shebang will be evaluated, etc.).

Some folks have asked why we have `pre-converge` and `post-converge` steps. The reason for this is because occasionally your cloud stack is going to require manual intervention. But you might want to react to that manual intervention before starting the next step--so you can prompt your operator to perform their manual task in Step X's `post-converge` and react to it in Step X+1's `pre-converge`.

While this gem _should_ in all cases be Windows-compatible, event scripts are the most likely place to run into jank. Your PowerShell and batch scripts _should_ work but this is not guaranteed. Bug reports and pull requests welcome. Obviously, running those scripts in a cross-platform way is a total no-go, so if you need to run in a cross-platform environment you should stick to writing your scripts in Ruby.

**Important:** `pre-converge` and `post-converge` _will_ run even if there are no changes applied to CloudFormation resources. This makes Auster a handy place to do stuff like rolling database credentials.

### Environment Variables in Event Scripts ###
- `PLAN_ID`: the identifier of this Auster stack, i.e., for `us-west-2/dev-ed1` `PLAN_ID` would equal `dev-ed1`.
- `AWS_REGION`/`AWS_DEFAULT_REGION`: the AWS region of this Auster stack

### Ruby Methods in Event Scripts ###
- `plan_id`: the identifier of this Auster stack, as per `PLAN_ID`.
- `aws_region`: the AWS region of this Auster stack, as per `AWS_REGION`.
- `repo`: the `Cfer::Auster::Repo` object representing the entire repo.
- `config_set`: the `Cfer::Auster:Config` object representing the collection of parameters related to this environment.
- `exports(export_plan_id = PLAN_ID)`: fetches all CloudFormation exports for a given plan (by default, the one of the secuting stack). The preferred method of accessing data from a dependent stack.
- `repo.step_by_tag(tag).cfn_data(config_set)`: retrieves all parameters and outputs of a given step and environment.

## Auster Cfer Scripts ##
**Note:** Auster wraps Cfer at an API level rather than at a command-line level, so feature parity is an ongoing process. In particular, stack policies are not currently supported--it's a mix of not having a Ruby DSL for them and not having a direct need for them myself at the moment. Pull requests welcome!

Auster uses a convention-based arrangement for structuring the Cfer scripts that will be processed into CloudFormation. The order of evaluation is as follows:

- `/cfer-helpers/**/*.rb` - global-scope helpers.
- `/steps/##.tag/cfer/helpers/**/*.rb` - script-scope helpers.
- `/steps/##.tag/cfer/require.rb` - intended for checking preconditions, requiring libraries used downstream (my favorite is `ipaddress`!), etc.
- `/steps/##.tag/cfer/parameters.rb` - intended for defining `parameter`s.
- `/steps/##.tag/cfer/exports.rb` - intended for defining `output`s and `export`s.
- `/steps/##.tag/cfer/defs/**/*.rb` - intended for defining `resource`s.

### Auster Cfer Helpers ###
- `import_value(name)`: Wrapper around `Fn::ImportValue` that prepends the current plan's ID to the name in question.
- `export(name, value)`: Wrapper around `output` to export the value in question. Prepends the plan's ID in the same way that `import_value` expects.

## Structure ##
Each Auster plan is laid out as per the following directory structure:

- `/`
  - `/.auster.yaml` - Currently empty; intended for future global configuration. (Necessary to find the base of a repo, a la Rakefile/Gemfiles.)
  - `/Gemfile` - Used for script dependencies, etc. as per usual. (You should probably require `auster` here too, to version-pin it.)
  - `/config`
    - `/schema.yaml` - (optional) a [Kwalify](http://www.kuwata-lab.com/kwalify/ruby/users-guide.html) schema against which a configuration file will be checked before any operations can be taken.
    - `/validator.rb` - (optional) a `Cfer::Auster::ParamValidator` that, if it exists, will be run against the parameter set _after_ YAML loading but _before_ Cfer is run.
    - `/us-west-2` - the AWS region for this configuration set. (This value is not typechecked.)
      - `/dev1-ed.yaml` - a YAML file that will be surfaced as Cfer parameters
        - The basename (filename sans extension) must begin with an alphabetic character and may only contain alphanumerics (case sensitive) and numbers. It must be under 16 characters in length.
        - The filename sans extension will be used as an identifier for steps executed with its configuration, i.e. the CloudFormation stack for `dev1-ed` will be called `dev1-ed-step00` and exports from a step in `dev1-ed` will be called `dev1-ed-YourExportName`.
          - This identifier is exposed in your Cfer scripts as `parameters[:AusterID]`.
        - This parameter set will be checked into source control and so should have _no_ secrets in it! This is for configuration parameters like:
          - VPC CIDR block allocation
          - Autoscaling group sizes
          - Instance sizes
          - Domain names (for feeding into Route 53)
        - The AWS region of this stack is exposed in your Cfer scripts as `parameters[:AWSRegion]`.
  - `/cfer-helpers`
    - A set of Ruby files that are included into every Cfer scope. Intended for global-scope helper methods.
  - `/steps`
    - `/00.human-tag`
      - `/cfer`
        - `/defs`
          - A set of Ruby files containing Cfer `resource` declarations. These will be evaluated in lexicographic order, but should not be reliant on behaviors in any other file!
        - `helpers`
          - A set of Ruby files that will be included into the Cfer scope. Intended for script-specific helper methods.
        - `/parameters.rb` - Cfer `parameter` invocations and `Auster.import` calls (which will be automatically prepended with the stack name).
        - `/outputs.rb` - Cfer `output` invocations and `Auster.export` calls (which will be automatically prepended with the stack name).
        - `/require.rb` - every other Cfer file will be executed in the context of `require.rb`. This is not guaranteed to be executed only once and so no stateful changes should be made here.
      - `/on-create.d`
        - A set of scripts to be run when the step is first executed.
      - `/on-destroy.d`
        - A set of scripts to be run when the Cfer stack is being torn down.
      - `/pre-converge.d`
        - A set of scripts to be run at the start of the Cfer run.
      - `/post-converge.d`
        - A set of scripts to be run at the successful end of the Cfer run.
    - `/01.human-tag`
      - ...
    - `/02.human-tag`
      - ...

## Contributing ##
Bug reports and pull requests are welcome on GitHub at https://github.com/eropple/cfer-auster. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. (And I mean it.)


## License ##
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

