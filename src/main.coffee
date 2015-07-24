fs = require 'fs'
path = require 'path'
_ = require 'lodash'

{jupyterPath} = require './paths'

ConfigManager = require './config-manager'
Kernel = require 'jupyter-session'

module.exports = KernelLauncher =
    kernelsDirOptions: jupyterPath('kernels')
    pythonInfo:
        display_name: "Python"
        language: "python"
    availableKernels: null

    getAvailableKernels: ->
        if @availableKernels?
            return @availableKernels
        else
            kernelLists = _.map @kernelsDirOptions, @getKernelsFromDirectory
            kernels = []
            kernels = kernels.concat.apply(kernels, kernelLists)
            kernels = _.map kernels, (kernel) =>
                kernel.language = @getTrueLanguage(kernel.language)
                return kernel

            pythonKernels = _.filter kernels, (kernel) ->
                return kernel.language == 'python'
            if pythonKernels.length == 0
                kernels.push(@pythonInfo)
            return kernels

    getKernelsFromDirectory: (directory) ->
        try
            kernelNames = fs.readdirSync directory
            kernels = _.map kernelNames, (name) =>
                kernelDirPath = path.join(directory, name)

                if fs.statSync(kernelDirPath).isDirectory()
                    kernelFilePath = path.join(kernelDirPath, 'kernel.json')
                    info = JSON.parse fs.readFileSync(kernelFilePath)
                    info.language ?= info.display_name.toLowerCase()
                    return info
                else
                    return null

            kernels = _.filter(kernels)
        catch error
            kernels = []
        return kernels

    getTrueLanguage: (language) ->
        return language.toLowerCase()

    getKernelInfoForLanguage: (language) ->
        kernels = @getAvailableKernels()
        language = @getTrueLanguage(language)

        matchingKernels = _.filter kernels, (kernel) ->
            kernelLanguage = kernel.language
            kernelLanguage ?= kernel.display_name

            return kernelLanguage? and
                   language.toLowerCase() == kernelLanguage.toLowerCase()

        if matchingKernels.length == 0
            return null
        else
            return matchingKernels[0]

    languageHasKernel: (language) ->
        return @getKernelInfoForLanguage(language)?

    startKernel: (language, onStarted) ->
        language = @getTrueLanguage(language)
        if @languageHasKernel(language)
            kernelInfo = @getKernelInfoForLanguage(language)

            # write a config to start the kernel with
            ConfigManager.writeConfigFile (configPath, config) ->

                # once the config is written, we can start up the kernel
                language = kernelInfo.language.toLowerCase()

                homeDir = process.env['HOME'] or
                          process.env['USERPROFILE'] or
                          path.resolve('~')

                homeDir = fs.realpathSync(homeDir)

                if language == 'python' and not kernelInfo.argv?
                    commandString = "ipython"
                    args = [
                        "kernel",
                        "--no-secure",
                        "--hb=#{config.hb_port}",
                        "--control=#{config.control_port}",
                        "--shell=#{config.shell_port}",
                        "--stdin=#{config.stdin_port}",
                        "--iopub=#{config.iopub_port}",
                        "--colors=NoColor"
                        ]

                else
                    commandString = _.first(kernelInfo.argv)
                    args = _.rest(kernelInfo.argv)
                    args = _.map args, (arg) =>
                        if arg == '{connection_file}'
                            return configPath
                        else
                            return arg

                console.log "launching kernel:", commandString, args
                kernelProcess = child_process.spawn(commandString, args, {
                        cwd: homeDir
                    })

                kernelProcess.stdout.on 'data', (data) ->
                    console.log "kernel process received on stdout:", data.toString()
                kernelProcess.stderr.on 'data', (data) ->
                    console.error "kernel process received on stderr:", data.toString()

                config.language = language
                config.signature_scheme = ConfigManager.SIGNATURE_SCHEME
                kernel = new Kernel(config, kernelProcess)
                onStarted?(kernel)
        else
            throw "No kernel available for language '#{language}'"
