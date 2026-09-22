# Rails wraps a JSON body under a key guessed from the controller name, so
# { "first_name": "Ada" } would quietly become { "employee": { ... } }.
#
# Turned off, because it makes one mistake much harder to read: a client that
# forgets the "employee" wrapper gets a 400 saying exactly that, instead of a
# 422 listing every required field as blank. The contract is then the same
# whatever the content type.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters false
end
