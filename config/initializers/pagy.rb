require 'pagy/extras/array'    # for array pagination
require 'pagy/extras/overflow' # handles pages beyond the limit

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:overflow] = :last_page
