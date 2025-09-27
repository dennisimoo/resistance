class StatisticsWorkers
    constructor: () ->

    newWorker: () ->
        return {
            onmessage: null,
            postMessage: (data) ->
                # Do nothing - stub implementation
        }
