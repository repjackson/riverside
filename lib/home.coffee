if Meteor.isClient 
    Template.home.onCreated ->
        @autorun => Meteor.subscribe 'latest_model_docs', 'log', ->
        @autorun => Meteor.subscribe 'latest_model_docs', 'product', ->
    Template.latest_activity.helpers
        activity_docs: ->
            Docs.find 
                model:'log'
    Template.latest_orders.onCreated ->
        @autorun => Meteor.subscribe 'latest_model_docs', 'transfer',->
            
            
            
    Template.latest_checkins.onCreated ->
        @autorun => Meteor.subscribe 'latest_model_docs','checkin', ->

if Meteor.isServer
    Meteor.publish 'latest_model_docs', (model)->
        Docs.find {
            model:model
        }, 
            sort:_timestamp:-1
            limit:10