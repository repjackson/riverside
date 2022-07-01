if Meteor.isClient 
    Template.home.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'log', ->
    Template.home.helpers
        activity_docs: ->
            Docs.find 
                model:'log'
    Template.home.onCreated ->
        @autorun => Meteor.subscribe 'latest_checkin_docs', ->
    Template.latest_orders.onCreated ->
        @autorun => Meteor.subscribe 'latest_order_docs', ->
    Template.home.helpers
        latest_checkin_docs: ->
            Docs.find 
                model:'checkin'
    Template.latest_orders.helpers
        latest_order_docs: ->
            Docs.find 
                model:'order'
                
