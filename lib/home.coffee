if Meteor.isClient 
    Template.home.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'log', ->
    Template.latest_activity.helpers
        activity_docs: ->
            Docs.find 
                model:'log'
    Template.latest_orders.onCreated ->
        @autorun => Meteor.subscribe 'latest_order_docs', ->
            
    Template.latest_checkins.onCreated ->
        @autorun => Meteor.subscribe 'latest_checkin_docs', ->
    Template.latest_checkins.helpers
        latest_checkin_docs: ->
            Docs.find 
                model:'checkin'
    Template.latest_orders.helpers
        latest_order_docs: ->
            Docs.find 
                model:'order'
                
