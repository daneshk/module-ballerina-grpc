/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.net.grpc.builder.syntaxtree;

import io.ballerina.compiler.syntax.tree.AbstractNodeFactory;
import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.BuiltinSimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectFieldNode;
import io.ballerina.compiler.syntax.tree.OptionalTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ParameterizedTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypeParameterNode;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.compiler.syntax.tree.UnionTypeDescriptorNode;
import org.ballerinalang.net.grpc.builder.constants.SyntaxTreeConstants;

public class TypeDescriptor {

    public static QualifiedNameReferenceNode getQualifiedNameReferenceNode(String modulePrefix, String identifier) {
        return NodeFactory.createQualifiedNameReferenceNode(
                AbstractNodeFactory.createIdentifierToken(modulePrefix),
                SyntaxTreeConstants.SYNTAX_TREE_COLON,
                AbstractNodeFactory.createIdentifierToken(identifier + " "));
    }

    public static OptionalTypeDescriptorNode getOptionalTypeDescriptorNode(String modulePrefix, String identifier) {
        return NodeFactory.createOptionalTypeDescriptorNode(
                getQualifiedNameReferenceNode(modulePrefix, identifier), SyntaxTreeConstants.SYNTAX_TREE_QUESTION_MARK);
    }

    public static UnionTypeDescriptorNode getUnionTypeDescriptorNode(TypeDescriptorNode lhs, TypeDescriptorNode rhs) {
        return NodeFactory.createUnionTypeDescriptorNode(lhs, SyntaxTreeConstants.SYNTAX_TREE_PIPE, rhs);
    }

    public static BuiltinSimpleNameReferenceNode getBuiltinSimpleNameReferenceNode(String name) {
        switch (name) {
            case "int" :
                return NodeFactory.createBuiltinSimpleNameReferenceNode(SyntaxKind.INT_TYPE_DESC, AbstractNodeFactory.createIdentifierToken(name + " "));
            default:
                return NodeFactory.createBuiltinSimpleNameReferenceNode(SyntaxKind.STRING_TYPE_DESC, AbstractNodeFactory.createIdentifierToken(name + " "));
        }
    }

    public static SimpleNameReferenceNode getSimpleNameReferenceNode(String name) {
        return NodeFactory.createSimpleNameReferenceNode(AbstractNodeFactory.createIdentifierToken(name + " "));
    }

    public static TypeParameterNode getTypeParameterNode(TypeDescriptorNode typeNode) {
        return NodeFactory.createTypeParameterNode(SyntaxTreeConstants.SYNTAX_TREE_IT, typeNode, SyntaxTreeConstants.SYNTAX_TREE_GT);
    }

    public static ParameterizedTypeDescriptorNode getParameterizedTypeDescriptorNode(String type, TypeDescriptorNode descriptorNode) {
        return NodeFactory.createParameterizedTypeDescriptorNode(
                AbstractNodeFactory.createIdentifierToken(type),
                getTypeParameterNode(descriptorNode)
        );
    }

    public static ArrayTypeDescriptorNode getArrayTypeDescriptorNode(String type) {
        return NodeFactory.createArrayTypeDescriptorNode(
                getBuiltinSimpleNameReferenceNode(type),
                SyntaxTreeConstants.SYNTAX_TREE_OPEN_BRACKET,
                null,
                SyntaxTreeConstants.SYNTAX_TREE_CLOSE_BRACKET
        );
    }

    public static TypeReferenceNode getTypeReferenceNode(Node typeName) {
        return NodeFactory.createTypeReferenceNode(
                SyntaxTreeConstants.SYNTAX_TREE_ASTERISK,
                typeName,
                SyntaxTreeConstants.SYNTAX_TREE_SEMICOLON
        );
    }

    public static ObjectFieldNode getObjectFieldNode(String visibility, String[] qualifiers, Node typeName, String fieldName) {
        NodeList qualifierList = NodeFactory.createEmptyNodeList();
        for (String qualifier : qualifiers) {
            qualifierList = qualifierList.add(AbstractNodeFactory.createIdentifierToken(qualifier + " "));
        }
        return NodeFactory.createObjectFieldNode(
                null,
                AbstractNodeFactory.createIdentifierToken("\n" + visibility + " "),
                qualifierList,
                typeName,
                AbstractNodeFactory.createIdentifierToken(fieldName),
                null,
                null,
                SyntaxTreeConstants.SYNTAX_TREE_SEMICOLON
        );
    }
}
