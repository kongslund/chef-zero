require 'json'
require 'chef_zero/rest_base'
require 'chef_zero/chef_data/acl_path'

module ChefZero
  module Endpoints
    # /organizations/ORG/<thing>/NAME/_acl/PERM
    # Where thing is:
    # clients, data, containers, cookbooks, environments
    # groups, roles, nodes, users
    # or
    # /organizations/ORG/organization/_acl/PERM
    # or
    # /users/NAME/_acl/PERM
    #
    # Where PERM is create,read,update,delete,grant
    class AclEndpoint < RestBase
      def validate_request(request)
        path = request.rest_path[0..-3]
        path = path[0..1] if path.size == 3 && path[0] == 'organizations' && %w(organization organizations).include?(path[2])
        acl_path = ChefData::AclPath.get_acl_data_path(path) # Strip off _acl/PERM
        perm = request.rest_path[-1]
        if !acl_path || !%w(read create update delete grant).include?(perm)
          raise RestErrorResponse.new(404, "Object not found: #{build_uri(request.base_uri, request.rest_path)}")
        end
        [acl_path, perm]
      end

      def get(request)
        raise RestErrorResponse.new(404, "Object not found: #{build_uri(request.base_uri, request.rest_path)}")
      end

      def put(request)
        path, perm = validate_request(request)
        acls = JSON.parse(get_data(request, path), :create_additions => false)
        acls[perm] = JSON.parse(request.body, :create_additions => false)[perm]
        set_data(request, path, JSON.pretty_generate(acls))
        json_response(200, {'uri' => "#{build_uri(request.base_uri, request.rest_path)}"})
      end

      # Remove these to get them doing 405 again like they ought to
      def post(request)
        raise RestErrorResponse.new(404, "Method not allowed: POST #{build_uri(request.base_uri, request.rest_path)}")
      end

      def delete(request)
        raise RestErrorResponse.new(404, "Method not allowed: DELETE #{build_uri(request.base_uri, request.rest_path)}")
      end
    end
  end
end